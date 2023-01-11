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

public enum RoleType: String, Codable {
    case owner
    case admin
    case normal
    case client

    public var translation: String {
        let key: String
        switch self {
        case .owner:
            key = "typeOwner"
        case .admin:
            key = "typeAdmin"
        case .normal:
            key = "typeNormal"
        case .client:
            key = "typeClient"
        }
        let localized = NSLocalizedString(key, comment: "")
        return localized
    }
}
