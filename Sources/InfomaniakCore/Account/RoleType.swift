//
//  RoleType.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 11.08.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import Foundation
import LocalizeKit

public enum RoleType: String, Codable {
    case owner
    case admin
    case normal
    case client

    public var translation: String {
        get {
            let translations = [
                RoleType.owner: "typeOwner".localized,
                RoleType.admin: "typeAdmin".localized,
                RoleType.normal: "typeNormal".localized,
                RoleType.client: "typeClient".localized
            ]
            return translations[self]!
        }
    }
}
