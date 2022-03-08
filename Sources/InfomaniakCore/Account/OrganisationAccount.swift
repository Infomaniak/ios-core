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

public class OrganisationAccount: Codable, Equatable {
    public let id: Int
    public let billingMailing: Bool
    public let noAccess: Bool
    public let billing: Bool
    public let legalEntityType: String
    public let name: String
    public let mailing: Bool
    public let createdAt: Date
    public let website: String?
    public let type: RoleType
    public let workspaceOnly: Bool
    public let logo: String?
    public var initials: String {
        return name.initials
    }

    public static func == (lhs: OrganisationAccount, rhs: OrganisationAccount) -> Bool {
        return lhs.id == rhs.id
    }
}
