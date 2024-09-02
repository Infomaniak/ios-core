/*
 Infomaniak Core - iOS
 Copyright (C) 2022 Infomaniak Network SA

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

@frozen public struct UserSecurity: Codable, Hashable {
    /// One-time password
    public let otp: Bool
    public let sms: Bool
    public let smsPhone: String
    public let yubikey: Bool
    public let infomaniakApplication: Bool
    /// Double auth
    public let doubleAuth: Bool
    public let remainingRescueCode: Int
    /// Date User Profile has been logged
    public let lastLoginAt: Date
    public let dateLastChangedPassword: Int
    /// Double auth method
    public let doubleAuthMethod: String
    public let authDevices: [UserAuthDevice]?
}
