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

public struct UserSecurity: Codable {
    /// One-time password
    public var otp: Bool
    public var sms: Bool
    public var smsPhone: String
    public var yubikey: Bool
    public var infomaniakApplication: Bool
    /// Double auth
    public var doubleAuth: Bool
    public var remainingRescueCode: Int
    /// Date User Profile has been logged
    public var lastLoginAt: Date
    public var dateLastChangedPassword: Int
    /// Double auth method
    public var doubleAuthMethod: String
    public var authDevices: [UserAuthDevice]?

    private enum CodingKeys: String, CodingKey {
        case otp
        case sms
        case smsPhone = "sms_phone"
        case yubikey
        case infomaniakApplication = "infomaniak_application"
        case doubleAuth = "double_auth"
        case remainingRescueCode = "remaining_rescue_code"
        case lastLoginAt = "last_login_at"
        case dateLastChangedPassword = "date_last_changed_password"
        case doubleAuthMethod = "double_auth_method"
        case authDevices = "auth_devices"
    }
}
