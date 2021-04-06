//
//  ApiFetcher.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 09.06.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import InfomaniakLogin
import Sentry

public protocol RefreshTokenDelegate {
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
    var refreshTokenDelegate: RefreshTokenDelegate!

    public init() {
    }

    public func setToken(_ token: ApiToken, delegate: RefreshTokenDelegate) {
        self.refreshTokenDelegate = delegate
        let authenticator = OAuthAuthenticator(refreshTokenDelegate: refreshTokenDelegate)
        let authenticationInterceptor = AuthenticationInterceptor(authenticator: authenticator, credential: token)

        let retrier = NetworkRequestRetrier()
        let interceptor = Interceptor(adapters: [], retriers: [retrier], interceptors: [authenticationInterceptor])
        authenticatedSession = Session(interceptor: interceptor)
    }

    public func handleResponse<Type>(response: DataResponse<Type, AFError>, completion: @escaping (Type?, Error?) -> Void) {
        switch response.result {
        case .success(let result):
            completion(result, nil)
            break
        case .failure(let error):
            if let data = response.data {
                if response.response!.statusCode == 500 {
                    SentrySDK.capture(error: error)
                }
                if let apiError = try? ApiFetcher.decoder.decode(ApiResponse<EmptyResponse>.self, from: data),
                    let error = apiError.error {
                    completion(nil, error)
                } else {
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
            break
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

open class OAuthAuthenticator: Authenticator {

    public typealias Credential = ApiToken

    let refreshTokenDelegate: RefreshTokenDelegate

    public init(refreshTokenDelegate: RefreshTokenDelegate) {
        self.refreshTokenDelegate = refreshTokenDelegate
    }

    public func apply(_ credential: Credential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(.authorization(bearerToken: credential.accessToken))
    }

    public func refresh(_ credential: Credential, for session: Session, completion: @escaping (Result<Credential, Error>) -> Void) {
        InfomaniakLogin.refreshToken(token: credential) { (token, error) in
            //New token has been fetched correctly
            if let token = token {
                self.refreshTokenDelegate.didUpdateToken(newToken: token, oldToken: credential)
                completion(.success(token))
            } else {
                //Couldn't refresh the token, API says it's invalid
                if error != nil && (error! as NSError).domain == "invalid_grant" {
                    self.refreshTokenDelegate.didFailRefreshToken(credential)
                    DispatchQueue.main.async {
                        completion(.failure(error!))
                        (UIApplication.shared.delegate as? RefreshTokenDelegate)?.didFailRefreshToken(credential)
                    }
                } else {
                    //Couldn't refresh the token, keep the old token and fetch it later. Maybe because of bad network ?
                    completion(.success(credential))
                }
            }
        }
    }

    public func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: Error) -> Bool {
        return response.statusCode == 401
    }

    public func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: ApiToken) -> Bool {
        return urlRequest.headers["Authorization"] == credential.accessToken
    }
}

extension ApiToken: AuthenticationCredential {

    public var requiresRefresh: Bool {
        return Date() > self.expirationDate
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
