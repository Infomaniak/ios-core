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

public class UserProfile: Codable, InfomaniakUser {
    public var id: Int
    public var displayName: String
    public var firstName: String
    public var lastName: String
    public var email: String
    public var avatar: String?
    public var login: String
    public var sessions: [UserSession]
    public var preferences: UserPreferences
    public var phones: [UserPhone]
    public var emails: [UserEmail]
    public var isStaff: Bool?

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

    public required init(from decoder: Decoder) throws {
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
            isStaff = try container.decodeIfPresent(Bool.self, forKey: .isStaff)
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
        }
    }
}
