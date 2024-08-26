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

@frozen public struct UserProfile: Codable, InfomaniakUser, Hashable {
    public let id: Int
    public let displayName: String
    public let firstName: String
    public let lastName: String
    public let email: String
    public let avatar: String?
    public let login: String
    public let sessions: [UserSession]
    public let preferences: UserPreferences
    public let phones: [UserPhone]
    public let emails: [UserEmail]
    public let isStaff: Bool?

    private enum OldCodingKeys: String, CodingKey {
        case id
        case userId
        case login
        case email
        case firstname
        case lastname
        case displayName
        case sms
        case smsPhone
        case doubleAuth
        case securityCheck
        case emailValidate
        case emailReminderValidate
        case phoneReminderValidate
        case avatar
        case phones
        case emails
    }

    public init(from decoder: Decoder) throws {
        var id: Int
        var displayName: String
        var firstName: String
        var lastName: String
        var email: String
        var avatar: String?
        var login: String
        var sessions: [UserSession]
        var preferences: UserPreferences
        var phones: [UserPhone]
        var emails: [UserEmail]
        var isStaff: Bool

        // Custom decoder to allow decoding old model (for account decoding)
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            displayName = try container.decode(String.self, forKey: .displayName)
            firstName = try container.decode(String.self, forKey: .firstName)
            lastName = try container.decode(String.self, forKey: .lastName)
            email = try container.decode(String.self, forKey: .email)
            avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
            login = try container.decode(String.self, forKey: .login)
            sessions = try container.decodeIfPresent([UserSession].self, forKey: .sessions) ?? []
            preferences = try container.decodeIfPresent(UserPreferences.self, forKey: .preferences) ?? UserPreferences()
            phones = try container.decodeIfPresent([UserPhone].self, forKey: .phones) ?? []
            emails = try container.decodeIfPresent([UserEmail].self, forKey: .emails) ?? []
            isStaff = try container.decodeIfPresent(Bool.self, forKey: .isStaff) ?? false
        } catch DecodingError.keyNotFound {
            // Try old coding keys
            let container = try decoder.container(keyedBy: OldCodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            displayName = try container.decode(String.self, forKey: .displayName)
            firstName = try container.decode(String.self, forKey: .firstname)
            lastName = try container.decode(String.self, forKey: .lastname)
            email = try container.decode(String.self, forKey: .email)
            avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
            login = try container.decode(String.self, forKey: .login)
            sessions = []
            preferences = UserPreferences()
            phones = []
            emails = []
            isStaff = false
        }

        self.id = id
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.avatar = avatar
        self.login = login
        self.sessions = sessions
        self.preferences = preferences
        self.phones = phones
        self.emails = emails
        self.isStaff = isStaff
    }
}
