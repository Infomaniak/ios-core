/*
Copyright 2020 Infomaniak Network SA

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import Foundation

/*
 Copyright 2020 Infomaniak Network SA

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
