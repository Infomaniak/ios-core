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
import Sentry

@objc public class ApiToken: NSObject, Codable {
    @objc public var accessToken: String
    @objc public var expiresIn: Int
    @objc public var refreshToken: String
    @objc public var scope: String
    @objc public var tokenType: String
    @objc public var userId: Int
    @objc public var expirationDate: Date

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case userId = "user_id"
        case scope
        case expirationDate
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        expiresIn = try values.decode(Int.self, forKey: .expiresIn)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
        scope = try values.decode(String.self, forKey: .scope)
        tokenType = try values.decode(String.self, forKey: .tokenType)
        userId = try values.decode(Int.self, forKey: .userId)

        let newExpirationDate = Date().addingTimeInterval(TimeInterval(Double(expiresIn)))
        expirationDate = try values.decodeIfPresent(Date.self, forKey: .expirationDate) ?? newExpirationDate
    }

    public init(accessToken: String, expiresIn: Int, refreshToken: String, scope: String, tokenType: String, userId: Int, expirationDate: Date) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
        self.userId = userId
        self.expirationDate = expirationDate
    }
}

// MARK: - Token Logging

extension ApiToken {
    var truncatedAccessToken: String {
        truncateToken(accessToken)
    }

    var truncatedRefreshToken: String {
        truncateToken(refreshToken)
    }

    private func truncateToken(_ token: String) -> String {
        String(token.prefix(4) + "-*****-" + token.suffix(4))
    }

    func generateBreadcrumb(level: SentryLevel, message: String, keychainError: OSStatus = noErr) -> Breadcrumb {
        let crumb = Breadcrumb(level: level, category: "Token")
        crumb.type = level == .info ? "info" : "error"
        crumb.message = message
        crumb.data = ["User id": userId,
                      "Expiration date": expirationDate.timeIntervalSince1970,
                      "Access Token": truncatedAccessToken,
                      "Refresh Token": truncatedRefreshToken,
                      "Keychain error code": keychainError]
        return crumb
    }
}
