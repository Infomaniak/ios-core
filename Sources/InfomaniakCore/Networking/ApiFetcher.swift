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
import InfomaniakLogin
import Sentry

public typealias EncodableParameters = [String: Encodable & Sendable]

public protocol RefreshTokenDelegate: AnyObject {
    func didUpdateToken(newToken: ApiToken, oldToken: ApiToken)
    func didFailRefreshToken(_ token: ApiToken)
}

open class ApiFetcher {
    enum ErrorDomain: Error {
        case noServerResponse
        case invalidJsonInBody
    }

    public typealias RequestModifier = (inout URLRequest) throws -> Void

    /// All status except 401 are handled by our code, 401 status is handled by Alamofire's Authenticator code
    private static var handledHttpStatus: Set<Int> = {
        var allStatus = Set(200 ... 500)
        allStatus.remove(401)
        return allStatus
    }()

    public var authenticatedSession: Session!

    public let decoder: JSONDecoder
    public let bodyEncoder: JSONEncoder

    private let jsonParameterEncoder: JSONParameterEncoder

    public var currentToken: ApiToken? {
        get {
            return authenticationInterceptor?.credential
        }
        set {
            authenticationInterceptor?.credential = newValue
        }
    }

    private weak var refreshTokenDelegate: RefreshTokenDelegate?
    private var authenticationInterceptor: AuthenticationInterceptor<OAuthAuthenticator>?

    public init(
        decoder: JSONDecoder? = nil,
        bodyEncoder: JSONEncoder? = nil
    ) {
        if let decoder {
            self.decoder = decoder
        } else {
            let defaultDecoder = JSONDecoder()
            defaultDecoder.dateDecodingStrategy = .secondsSince1970
            defaultDecoder.keyDecodingStrategy = .convertFromSnakeCase
            self.decoder = defaultDecoder
        }
        if let bodyEncoder {
            self.bodyEncoder = bodyEncoder
            jsonParameterEncoder = JSONParameterEncoder(encoder: bodyEncoder)
        } else {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                try container.encode(Int(date.timeIntervalSince1970))
            }
            self.bodyEncoder = encoder
            jsonParameterEncoder = JSONParameterEncoder(encoder: encoder)
        }
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
        let authenticationInterceptor = AuthenticationInterceptor(authenticator: authenticator, credential: token)
        self.authenticationInterceptor = authenticationInterceptor

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
        let authenticationInterceptor = AuthenticationInterceptor(authenticator: authenticator, credential: token)
        self.authenticationInterceptor = authenticationInterceptor

        let retrier = NetworkRequestRetrier()
        let interceptor = Interceptor(adapters: additionalAdapters,
                                      retriers: [retrier] + additionalRetriers,
                                      interceptors: [authenticationInterceptor] + additionalInterceptors)
        authenticatedSession = Session(interceptor: interceptor)
    }

    // MARK: - Request helpers

    public func authenticatedRequest(_ endpoint: Endpoint,
                                     method: HTTPMethod = .get,
                                     parameters: EncodableParameters? = nil,
                                     overrideEncoder: ParameterEncoder? = nil,
                                     headers: HTTPHeaders? = nil,
                                     requestModifier: RequestModifier? = nil) -> DataRequest {
        let encodableParameters: EncodableDictionary?
        if let parameters {
            encodableParameters = EncodableDictionary(parameters)
        } else {
            encodableParameters = nil
        }

        return authenticatedRequest(
            endpoint,
            method: method,
            parameters: encodableParameters,
            overrideEncoder: overrideEncoder,
            headers: headers,
            requestModifier: requestModifier
        )
    }

    public func authenticatedRequest<Parameters: Encodable>(_ endpoint: Endpoint,
                                                            method: HTTPMethod = .get,
                                                            parameters: Parameters? = nil,
                                                            overrideEncoder: ParameterEncoder? = nil,
                                                            headers: HTTPHeaders? = nil,
                                                            requestModifier: RequestModifier? = nil) -> DataRequest {
        let encoder = overrideEncoder ?? jsonParameterEncoder
        return authenticatedSession
            .request(
                endpoint.url,
                method: method,
                parameters: parameters,
                encoder: encoder,
                headers: headers,
                requestModifier: requestModifier
            )
    }

    open func perform<T: Decodable>(request: DataRequest, overrideDecoder: JSONDecoder? = nil) async throws -> T {
        return try await perform(request: request, overrideDecoder: overrideDecoder).validApiResponse.data
    }

    open func perform<T: Decodable>(request: DataRequest,
                                    overrideDecoder: JSONDecoder? = nil) async throws -> ValidServerResponse<T> {
        let validatedRequest = request.validate(statusCode: ApiFetcher.handledHttpStatus)

        let requestDecoder = overrideDecoder ?? decoder
        let dataResponse = await validatedRequest.serializingDecodable(ApiResponse<T>.self,
                                                                       automaticallyCancelling: true,
                                                                       decoder: requestDecoder).response

        SentryDebug.httpResponseBreadcrumb(urlRequest: request.convertible.urlRequest, urlResponse: dataResponse.response)

        do {
            return try handleApiResponse(dataResponse)
        } catch {
            @InjectService var errorRegistry: IKErrorRegistry

            guard let afError = error.asAFError else {
                throw errorRegistry.unknownError(underlyingError: error, shouldDisplay: false)
            }

            if case .responseSerializationFailed(let reason) = afError,
               case .decodingFailed(let error) = reason,
               let statusCode = request.response?.statusCode, (200 ... 299).contains(statusCode) {
                var rawJson = "No data"
                if let data = request.data {
                    rawJson = String(decoding: data, as: UTF8.self)
                }

                let requestId = request.response?.value(forHTTPHeaderField: "x-request-id") ?? "No request Id"
                SentrySDK.capture(error: error) { scope in
                    scope.setExtras(["Request URL": request.request?.url?.absoluteString ?? "No URL",
                                     "Request Id": requestId,
                                     "Decoded type": String(describing: T.self),
                                     "Raw JSON": rawJson])
                }
            } else if let underlyingError = afError.underlyingError,
                      (underlyingError as NSError).code == NSURLErrorNotConnectedToInternet ||
                      (underlyingError as NSError).code == NSURLErrorTimedOut {
                throw errorRegistry.networkError(underlyingError: afError)
            }

            throw errorRegistry.unknownError(underlyingError: error, shouldDisplay: false)
        }
    }

    open func handleApiResponse<T: Decodable>(_ dataResponse: DataResponse<ApiResponse<T>, AFError>) throws
        -> ValidServerResponse<T> {
        let apiResponse = try dataResponse.result.get()

        // This value should not be null because dataResponse.result.get should throw before
        guard let serverResponse = dataResponse.response else {
            throw ErrorDomain.noServerResponse
        }

        let responseData: T
        if let data = apiResponse.data {
            responseData = data
        } else if let NullableType = T.self as? ExpressibleByNilLiteral.Type,
                  let value = NullableType.init(nilLiteral: ()) as? T {
            responseData = value
        } else if let apiError = apiResponse.error {
            @InjectService var errorRegistry: IKErrorRegistry
            throw errorRegistry.apiError(apiError, statusCode: serverResponse.statusCode)
        } else {
            @InjectService var errorRegistry: IKErrorRegistry
            throw errorRegistry.serverError(statusCode: serverResponse.statusCode)
        }
        let validApiResponse = ValidApiResponse(
            result: apiResponse.result,
            data: responseData,
            total: apiResponse.total,
            pages: apiResponse.pages,
            page: apiResponse.page,
            itemsPerPage: apiResponse.itemsPerPage,
            responseAt: apiResponse.responseAt,
            cursor: apiResponse.cursor,
            hasMore: apiResponse.hasMore
        )
        return ValidServerResponse(
            statusCode: serverResponse.statusCode,
            responseHeaders: serverResponse.headers,
            validApiResponse: validApiResponse
        )
    }

    public func userOrganisations() async throws -> [OrganisationAccount] {
        try await perform(request: authenticatedRequest(.organisationAccounts))
    }

    public func userProfile(ignoreDefaultAvatar: Bool = false, dateFormat: DateFormat = .json) async throws -> UserProfile {
        try await perform(request: authenticatedRequest(
            .profile(ignoreDefaultAvatar: ignoreDefaultAvatar),
            headers: ["X-Date-Format": dateFormat.rawValue]
        ))
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
        networkLogin.refreshToken(token: credential) { result in
            switch result {
            case .success(let token):
                // New token has been fetched correctly
                self.refreshTokenDelegate?.didUpdateToken(newToken: token, oldToken: credential)
                completion(.success(token))
            case .failure(let error):
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
        guard let expirationDate else {
            return false
        }
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
