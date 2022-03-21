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

import Kingfisher
import UIKit

public protocol InfomaniakUser {
    var id: Int { get }
    var email: String { get }
    var displayName: String { get }
    var avatar: String { get }

    func getAvatar(size: CGSize, completion: @escaping (UIImage) -> Void)
}

public extension InfomaniakUser {
    func getAvatar(size: CGSize = CGSize(width: 40, height: 40), completion: @escaping (UIImage) -> Void) {
        if let url = URL(string: avatar) {
            KingfisherManager.shared.retrieveImage(with: url) { result in
                if let avatarImage = try? result.get().image {
                    completion(avatarImage)
                }
            }
        } else {
            let backgroundColor = UIColor.backgroundColor(from: id)
            completion(UIImage.getInitialsPlaceholder(with: displayName, size: size, backgroundColor: backgroundColor))
        }
    }
}

public class UserProfile: Codable, InfomaniakUser {
    public var id: Int
    public var displayName: String
    public var firstName: String
    public var lastName: String
    public var email: String
    public var avatar: String
    public var login: String
    public var sessions: [UserSession]?
    public var preferences: UserPreferences
    public var phones: [UserPhone]
    public var emails: [UserEmail]

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case avatar
        case login
        case sessions
        case preferences
        case phones
        case emails
    }
}

public struct UserSession: Codable {
    public var browser: String
    public var lastAccessedAt: Date
    public var device: String
    public var location: String
    public var ip: String
    public var userAgent: String

    private enum CodingKeys: String, CodingKey {
        case browser
        case lastAccessedAt = "last_accessed_at"
        case device
        case location
        case ip
        case userAgent = "user_agent"
    }
}

public struct UserPreferences: Codable {
    public var security: String?
    // public var account: String?
    public var connection: UserConnection?
    public var language: UserLanguage?
    public var country: UserCountry?
    public var timezone: UserTimezone?
}

public struct UserConnection: Codable {
    public var unsuccessfulLimit: Bool
    public var unsuccessfulRateLimit: Int
    public var unsuccessfulNotification: Bool
    public var successfulNotification: Bool

    private enum CodingKeys: String, CodingKey {
        case unsuccessfulLimit = "unsuccessful_limit"
        case unsuccessfulRateLimit = "unsuccessful_rate_limit"
        case unsuccessfulNotification = "unsuccessful_notification"
        case successfulNotification = "successful_notification"
    }
}

public struct UserLanguage: Codable {
    public var id: Int
    public var name: String
    public var shortName: String
    public var locale: String
    public var shortLocale: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case locale
        case shortLocale = "short_locale"
    }
}

public struct UserCountry: Codable {
    public var id: Int
    public var name: String
    public var shortName: String
    public var isEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case isEnabled = "is_enabled"
    }
}

public struct UserTimezone: Codable {
    public var id: Int
    public var name: String
    public var gmt: String
}

public struct UserPhone: Codable {
    public var id: Int
    public var phone: String
    public var createdAt: Date
    public var reminder: Bool
    public var checked: Bool
    public var type: String

    private enum CodingKeys: String, CodingKey {
        case id
        case phone
        case createdAt = "created_at"
        case reminder
        case checked
        case type
    }
}

public struct UserEmail: Codable {
    public var id: Int
    public var email: String
    public var createdAt: Date
    public var reminder: Bool
    public var checked: Bool
    public var type: String

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case reminder
        case checked
        case type
    }
}
