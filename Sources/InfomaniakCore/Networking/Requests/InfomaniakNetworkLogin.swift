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

import Foundation

public enum Constants {
    public static let LOGIN_URL = "https://login.infomaniak.com/"
    public static let DELETEACCOUNT_URL = "https://manager.infomaniak.com/v3/ng/profile/user/dashboard?open-terminate-account-modal"
    public static let RESPONSE_TYPE = "code"
    public static let ACCESS_TYPE = "offline"
    public static let HASH_MODE = "SHA-256"
    public static let HASH_MODE_SHORT = "S256"

    public static func autologinUrl(to destination: String) -> URL? {
        return URL(string: "https://manager.infomaniak.com/v3/mobile_login/?url=\(destination)")
    }
}

public class InfomaniakNetworkLogin {
    private static let LOGIN_API_URL = "https://login.infomaniak.com/"
    private static let GET_TOKEN_API_URL = LOGIN_API_URL + "token"

    private static let instance = InfomaniakNetworkLogin()

    private var clientId: String!
    private var loginBaseUrl: String!
    private var redirectUri: String!

    private var codeChallenge: String!
    private var codeChallengeMethod: String!
    private var codeVerifier: String!

    private init() {
        // Singleton
    }

    public static func initWith(clientId: String,
                                loginUrl: String = Constants.LOGIN_URL,
                                redirectUri: String = "\(Bundle.main.bundleIdentifier ?? "")://oauth2redirect") {
        instance.loginBaseUrl = loginUrl
        instance.clientId = clientId
        instance.redirectUri = redirectUri
    }

    /// Get an api token async (callback on background thread)
    public static func getApiTokenUsing(code: String, codeVerifier: String, completion: @escaping (ApiToken?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: GET_TOKEN_API_URL)!)

        let parameterDictionary: [String: Any] = [
            "grant_type": "authorization_code",
            "client_id": instance.clientId!,
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": instance.redirectUri ?? ""
        ]
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    /// Get an api token async from an application password (callback on background thread)
    public static func getApiToken(username: String, applicationPassword: String, completion: @escaping (ApiToken?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: GET_TOKEN_API_URL)!)

        let parameterDictionary: [String: Any] = [
            "grant_type": "password",
            "access_type": "offline",
            "client_id": instance.clientId!,
            "username": username,
            "password": applicationPassword
        ]
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    /// Refresh api token async (callback on background thread)
    public static func refreshToken(token: ApiToken, completion: @escaping (ApiToken?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: GET_TOKEN_API_URL)!)

        let parameterDictionary: [String: Any] = [
            "grant_type": "refresh_token",
            "client_id": instance.clientId!,
            "refresh_token": token.refreshToken
        ]
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterDictionary.percentEncoded()

        getApiToken(request: request, completion: completion)
    }

    /// Delete an api token async
    public static func deleteApiToken(token: ApiToken, onError: @escaping (Error) -> Void) {
        var request = URLRequest(url: URL(string: GET_TOKEN_API_URL)!)
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, sessionError in
            guard let response = response as? HTTPURLResponse, let data else {
                if let sessionError {
                    onError(sessionError)
                }
                return
            }

            do {
                if !response.isSuccessful() {
                    let apiDeleteToken = try JSONDecoder().decode(ApiDeleteToken.self, from: data)
                    onError(NSError(domain: apiDeleteToken.error!, code: response.statusCode, userInfo: ["Error": apiDeleteToken.error!]))
                }
            } catch {
                onError(error)
            }
        }.resume()
    }

    /// Make the get token network call
    private static func getApiToken(request: URLRequest, completion: @escaping (ApiToken?, Error?) -> Void) {
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, sessionError in
            guard let response = response as? HTTPURLResponse,
                  let data = data, data.count > 0 else {
                completion(nil, sessionError)
                return
            }

            do {
                if response.isSuccessful() {
                    let apiToken = try JSONDecoder().decode(ApiToken.self, from: data)
                    completion(apiToken, nil)
                } else {
                    let apiError = try JSONDecoder().decode(LoginApiError.self, from: data)
                    completion(nil, NSError(domain: apiError.error, code: response.statusCode, userInfo: ["Error": apiError]))
                }
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
}

extension HTTPURLResponse {
    func isSuccessful() -> Bool {
        return statusCode >= 200 && statusCode <= 299
    }
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
