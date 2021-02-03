//
//  OrganisationAccount.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 15.06.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

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
            let words = name.split(separator: " ")
            var initials = String(words[0].first!).capitalized
            if words.count > 1 {
                initials = initials + String(words[1].first!).capitalized
            }
            return initials
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
