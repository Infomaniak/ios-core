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

import UIKit

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
        get {
            return name.initials
        }
    }
    public var backgroundColor: UIColor {
        get {
            let nameAscii: [Int32] = name.replacingOccurrences(of: "/[^a-zA-Z ]+/", with: "", options: [.regularExpression]).compactMap({ $0.asciiValue }).compactMap({ Int32($0) })
            let hashCode: Int32 = nameAscii.reduce(0) { (a, b) in
                return ((a &<< Int32(5)) &- a) &+ Int32(b)
            }
            let colorIndex = (abs(Int(hashCode)) &+ id) % 8
            return UIColor(named: "organisationColor\(colorIndex)")!
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case billingMailing = "billing_mailing"
        case noAccess = "no_access"
        case billing
        case legalEntityType = "legal_entity_type"
        case name
        case mailing
        case createdAt = "created_at"
        case website
        case type
        case workspaceOnly = "workspace_only"
        case logo
    }

    public static func == (lhs: OrganisationAccount, rhs: OrganisationAccount) -> Bool {
        return lhs.id == rhs.id
    }

}
