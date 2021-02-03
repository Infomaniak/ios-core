//
//  UserDefaults+Extension.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 15.06.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import Foundation

public extension UserDefaults {

    private static let keyFirstLaunch = "isFirstLaunch"
    private static let keyCurrentUserId = "currentUserId"

    static func store(firstLaunch: Bool) {
        UserDefaults.standard.set(firstLaunch, forKey: keyFirstLaunch)
    }

    static func isFirstLaunch() -> Bool {
        if(UserDefaults.standard.object(forKey: keyFirstLaunch) != nil) {
            return UserDefaults.standard.bool(forKey: keyFirstLaunch)
        } else {
            return true
        }
    }

    static func store(currentUserId: Int) {
        UserDefaults.standard.set(currentUserId, forKey: keyCurrentUserId)
    }

    static func getCurrentUserId() -> Int {
        return UserDefaults.standard.integer(forKey: keyCurrentUserId)
    }
}
