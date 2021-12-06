/*
 Infomaniak Core - iOS
 Copyright (C) 2021 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Alamofire
import Foundation
import InfomaniakLogin
import Sentry
import UIKit

public protocol RefreshTokenDelegate: AnyObject {
    func didUpdateToken(newToken: ApiToken, oldToken: ApiToken)
    func didFailRefreshToken(_ token: ApiToken)
}

open class ApiFetcher {
    public let apiURL = "https://api.infomaniak.com/1/"

    public var authenticatedSession: Session!
    public static var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    public var currentToken: ApiToken? {
        get {
            return authenticationInterceptor.credential
        }
        set {
            authenticationInterceptor.credential = newValue
        }
    }

    private weak var refreshTokenDelegate: RefreshTokenDelegate?
    private var authenticationInterceptor: AuthenticationInterceptor<OAuthAuthenticator>!

    public init() {
        // Allow overriding
    }

    /**
        Creates a new authenticated session for the given token.
        The delegate is called back every time the token is refreshed.

        An [OAuthAuthenticator](x-source-tag://OAuthAuthenticator) is created to handle token refresh.

        - Parameter token: The token used to authenticate requests.
        - Parameter delegate: The delegate called on token refresh.
     */
    public func setToken(_ token: ApiToken, delegate: RefreshTokenDelegate) {
        let authenticator = OAuthAuthenticator(refreshTokenDelegate: delegate)
        setToken(token, authenticator: authenticator)
    }

    /**
        Creates a new authenticated session for the given token.
        The delegate is called back every time the token is refreshed.

        - Parameter token: The token used to authenticate requests.
        - Parameter authenticator: The custom authenticator used to refresh the token.
     */
    public func setToken(_ token: ApiToken, authenticator: OAuthAuthenticator) {
        refreshTokenDelegate = authenticator.refreshTokenDelegate
        authenticationInterceptor = AuthenticationInterceptor(authenticator: authenticator, credential: token)

        let retrier = NetworkRequestRetrier()
        let interceptor = Interceptor(adapters: [], retriers: [retrier], interceptors: [authenticationInterceptor])
        authenticatedSession = Session(interceptor: interceptor)
    }

    open func handleResponse<Type>(response: DataResponse<Type, AFError>, completion: @escaping (Type?, Error?) -> Void) {
        switch response.result {
        case .success(let result):
            completion(result, nil)
        case .failure(let error):
            if let data = response.data {
                if let response = response.response,
                   response.statusCode == 500 {
                    SentrySDK.capture(error: error) { scope in
                        let body = String(data: data, encoding: .utf8) ?? "Couldn't convert body to data"
                        scope.setContext(value: ["Headers": response.allHeaderFields, "Body": body], key: "Server error infos")
                    }
                }

                let apiError = try? ApiFetcher.decoder.decode(ApiResponse<EmptyResponse>.self, from: data).error
                completion(nil, apiError ?? error)
            } else {
                completion(nil, error)
            }
        }
    }

    public func getUserOrganisationAccounts(completion: @escaping (ApiResponse<[OrganisationAccount]>?, Error?) -> Void) {
        authenticatedSession.request("\(apiURL)account?with=logo&order_by=name").validate().responseDecodable(of: ApiResponse<[OrganisationAccount]>.self, decoder: ApiFetcher.decoder) { response in
            self.handleResponse(response: response, completion: completion)
        }
    }

    public func getUserForAccount(completion: @escaping (ApiResponse<UserProfile>?, Error?) -> Void) {
        authenticatedSession.request("\(apiURL)profile?with=avatar,phones,emails").validate().responseDecodable(of: ApiResponse<UserProfile>.self, decoder: ApiFetcher.decoder) { response in
            self.handleResponse(response: response, completion: completion)
        }
    }
}

/// - Tag: OAuthAuthenticator
open class OAuthAuthenticator: Authenticator {
    public typealias Credential = ApiToken

    public weak var refreshTokenDelegate: RefreshTokenDelegate?

    public init(refreshTokenDelegate: RefreshTokenDelegate) {
        self.refreshTokenDelegate = refreshTokenDelegate
    }

    open func apply(_ credential: Credential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(.authorization(bearerToken: credential.accessToken))
    }

    open func refresh(_ credential: Credential, for session: Session, completion: @escaping (Result<Credential, Error>) -> Void) {
        InfomaniakLogin.refreshToken(token: credential) { token, error in
            // New token has been fetched correctly
            if let token = token {
                self.refreshTokenDelegate?.didUpdateToken(newToken: token, oldToken: credential)
                completion(.success(token))
            } else {
                // Couldn't refresh the token, API says it's invalid
                if let error = error as NSError?, error.domain == "invalid_grant" {
                    self.refreshTokenDelegate?.didFailRefreshToken(credential)
                    completion(.failure(error))
                } else {
                    // Couldn't refresh the token, keep the old token and fetch it later. Maybe because of bad network ?
                    completion(.success(credential))
                }
            }
        }
    }

    open func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: Error) -> Bool {
        return response.statusCode == 401
    }

    open func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: ApiToken) -> Bool {
        let bearerToken = HTTPHeader.authorization(bearerToken: credential.accessToken).value
        return urlRequest.headers["Authorization"] == bearerToken
    }
}

extension ApiToken: AuthenticationCredential {
    public var requiresRefresh: Bool {
        return Date() > expirationDate
    }
}

class NetworkRequestRetrier: RequestInterceptor {
    let maxRetry: Int
    private var retriedRequests: [String: Int] = [:]

    init(maxRetry: Int = 3) {
        self.maxRetry = maxRetry
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard
            request.task?.response == nil,
            let url = request.request?.url?.absoluteString
        else {
            removeCachedUrlRequest(url: request.request?.url?.absoluteString)
            completion(.doNotRetry)
            return
        }

        let errorGenerated = error as NSError
        switch errorGenerated.code {
        // -1001 = timeout | -1005 = connection lost
        case -1001, -1005:
            guard let retryCount = retriedRequests[url] else {
                retriedRequests[url] = 1
                completion(.retryWithDelay(0.5))
                return
            }

            if retryCount < maxRetry {
                retriedRequests[url] = retryCount + 1
                completion(.retryWithDelay(0.5))
            } else {
                removeCachedUrlRequest(url: url)
                completion(.doNotRetry)
            }

        default:
            removeCachedUrlRequest(url: url)
            completion(.doNotRetry)
        }
    }

    private func removeCachedUrlRequest(url: String?) {
        guard let url = url else {
            return
        }
        retriedRequests.removeValue(forKey: url)
    }
}
