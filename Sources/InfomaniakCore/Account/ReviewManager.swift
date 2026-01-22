/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import StoreKit
import SwiftUI

extension UserDefaults.Keys {
    static let actionUntilReview = UserDefaults.Keys(rawValue: "actionUntilReview")
    static let alreadyAsked = UserDefaults.Keys(rawValue: "alreadyAsked")
}

public extension UserDefaults {
    var actionUntilReview: Int {
        get {
            return integer(forKey: key(.actionUntilReview))
        }
        set {
            set(newValue, forKey: key(.actionUntilReview))
        }
    }

    var alreadyAskedReview: Bool {
        get {
            if object(forKey: key(.alreadyAsked)) == nil {
                return false
            }
            return bool(forKey: key(.alreadyAsked))
        }
        set {
            set(newValue, forKey: key(.alreadyAsked))
        }
    }
}

public protocol ReviewManageable {
    func decreaseActionUntilReview()
    func shouldRequestReview() -> Bool
    func requestReview()
}

public class ReviewManager: ReviewManageable {
    let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults, actionBeforeFirstReview: Int) {
        self.userDefaults = userDefaults
        if userDefaults.object(forKey: userDefaults.key(.actionUntilReview)) == nil {
            userDefaults.set(actionBeforeFirstReview, forKey: userDefaults.key(.actionUntilReview))
        }
    }

    public func decreaseActionUntilReview() {
        userDefaults.actionUntilReview -= 1
    }

    public func shouldRequestReview() -> Bool {
        if userDefaults.actionUntilReview <= 0 && !userDefaults.alreadyAskedReview {
            userDefaults.alreadyAskedReview = true
            return true
        } else {
            return false
        }
    }

    public func requestReview() {
        DispatchQueue.main.async {
            #if canImport(UIKit)
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
            #else
            SKStoreReviewController.requestReview()
            #endif
        }
    }
}
