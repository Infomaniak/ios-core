/*
 Infomaniak Core - iOS
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakDI
import Sentry

public protocol RefreshTokenDelegate: AnyObject {
    func didUpdateToken(newToken: ApiToken, oldToken: ApiToken)
    func didFailRefreshToken(_ token: ApiToken)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class ApiFetcher {
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

    /// Creates a new authenticated session for the given token.
    ///
    /// The delegate is called back every time the token is refreshed.
    /// An [OAuthAuthenticator](x-source-tag://OAuthAuthenticator) is created to handle token refresh.
    ///
    /// - Parameter token: The token used to authenticate requests.
    /// - Parameter delegate: The delegate called on token refresh.
    public func setToken(_ token: ApiToken, delegate: RefreshTokenDelegate) {
        let authenticator = OAuthAuthenticator(refreshTokenDelegate: delegate)
        createAuthenticatedSession(token, authenticator: authenticator)
    }

    @available(*, deprecated, message: "Use createAuthenticatedSession instead")
    public func setToken(_ token: ApiToken, authenticator: OAuthAuthenticator) {
        refreshTokenDelegate = authenticator.refreshTokenDelegate
        authenticationInterceptor = AuthenticationInterceptor(authenticator: authenticator, credential: token)

        let retrier = NetworkRequestRetrier()
        let interceptor = Interceptor(adapters: [], retriers: [retrier], interceptors: [authenticationInterceptor])
        authenticatedSession = Session(interceptor: interceptor)
    }

    /// Creates a new authenticated session for the given token.
    ///
    /// The delegate is called back every time the token is refreshed.
    /// - Parameter token: The token used to authenticate requests.
    /// - Parameter authenticator: The custom authenticator used to refresh the token.
    public func createAuthenticatedSession(_ token: ApiToken,
                                           authenticator: OAuthAuthenticator,
                                           additionalAdapters: [RequestAdapter] = [],
                                           additionalRetriers: [RequestRetrier] = [],
                                           additionalInterceptors: [RequestInterceptor] = []) {
        refreshTokenDelegate = authenticator.refreshTokenDelegate
        authenticationInterceptor = AuthenticationInterceptor(authenticator: authenticator, credential: token)

        let retrier = NetworkRequestRetrier()
        let interceptor = Interceptor(adapters: additionalAdapters,
                                      retriers: [retrier] + additionalRetriers,
                                      interceptors: [authenticationInterceptor] + additionalInterceptors)
        authenticatedSession = Session(interceptor: interceptor)
    }

    // MARK: - Request helpers

    open func authenticatedRequest(_ endpoint: Endpoint,
                                   method: HTTPMethod = .get,
                                   parameters: Parameters? = nil,
                                   encoding: ParameterEncoding = JSONEncoding.default,
                                   headers: HTTPHeaders? = nil) -> DataRequest {
        return authenticatedSession
            .request(endpoint.url, method: method, parameters: parameters, encoding: encoding, headers: headers)
    }

    open func authenticatedRequest<Parameters: Encodable>(_ endpoint: Endpoint,
                                                          method: HTTPMethod = .get,
                                                          parameters: Parameters? = nil) -> DataRequest {
        return authenticatedSession
            .request(endpoint.url, method: method, parameters: parameters, encoder: JSONParameterEncoder.convertToSnakeCase)
    }

    open func perform<T: Decodable>(request: DataRequest,
                                    decoder: JSONDecoder = ApiFetcher.decoder) async throws -> (data: T, responseAt: Int?) {
        let response = await request.serializingDecodable(ApiResponse<T>.self,
                                                          automaticallyCancelling: true,
                                                          decoder: decoder).response
        let apiResponse = try response.result.get()
        return try handleApiResponse(apiResponse, responseStatusCode: response.response?.statusCode ?? -1)
    }
    
    open func handleApiResponse<T: Decodable>(_ response: ApiResponse<T>, responseStatusCode: Int) throws -> (data: T, responseAt: Int?) {
        if let responseData = response.data {
            return (responseData, response.responseAt)
        } else if let apiError = response.error {
            throw InfomaniakError.apiError(apiError)
        } else {
            throw InfomaniakError.serverError(statusCode: responseStatusCode)
        }
    }

    public func userOrganisations() async throws -> [OrganisationAccount] {
        try await perform(request: authenticatedRequest(.organisationAccounts)).data
    }

    public func userProfile() async throws -> UserProfile {
        try await perform(request: authenticatedRequest(.profile)).data
    }
}

/// - Tag: OAuthAuthenticator
open class OAuthAuthenticator: Authenticator {
    @InjectService var networkLogin: InfomaniakNetworkLoginable

    public typealias Credential = ApiToken

    public weak var refreshTokenDelegate: RefreshTokenDelegate?

    public init(refreshTokenDelegate: RefreshTokenDelegate) {
        self.refreshTokenDelegate = refreshTokenDelegate
    }

    open func apply(_ credential: Credential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(.authorization(bearerToken: credential.accessToken))
    }

    open func refresh(_ credential: Credential, for session: Session, completion: @escaping (Result<Credential, Error>) -> Void) {
        networkLogin.refreshToken(token: credential) { token, error in
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

    open func didRequest(_ urlRequest: URLRequest,
                         with response: HTTPURLResponse,
                         failDueToAuthenticationError error: Error) -> Bool {
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

    func retry(_ request: Alamofire.Request,
               for session: Session,
               dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
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
