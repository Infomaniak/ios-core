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
    static let openingUntilReview = UserDefaults.Keys(rawValue: "openingUntilReview")
    static let appReview = UserDefaults.Keys(rawValue: "appReview")
}

public extension UserDefaults {
    var openingUntilReview: Int {
        get {
            return integer(forKey: key(.openingUntilReview))
        }
        set {
            set(newValue, forKey: key(.openingUntilReview))
        }
    }

    var appReview: ReviewType {
        get {
            return ReviewType(rawValue: string(forKey: key(.appReview)) ?? "") ?? .none
        }
        set {
            set(newValue.rawValue, forKey: key(.appReview))
        }
    }
}

public enum ReviewType: String {
    case none
    case feedback
    case readyForReview
}

public protocol ReviewManageable {
    func decreaseOpeningUntilReview()
    func shouldRequestReview() -> Bool
    func requestReview()
}

public class ReviewManager: ReviewManageable {
    let userDefaults: UserDefaults
    let openingBeforeNextReviews: Int

    private var userHasAlreadyAnsweredYes: Bool {
        return userDefaults.appReview == .readyForReview
    }

    public init(userDefaults: UserDefaults, openingBeforeFirstReview: Int = 50, openingBeforeNextReviews: Int = 500) {
        self.userDefaults = userDefaults
        self.openingBeforeNextReviews = openingBeforeNextReviews
        if userDefaults.object(forKey: userDefaults.key(.openingUntilReview)) == nil {
            userDefaults.set(openingBeforeFirstReview, forKey: userDefaults.key(.openingUntilReview))
        }
    }

    public func decreaseOpeningUntilReview() {
        userDefaults.openingUntilReview -= 1
    }

    public func shouldRequestReview() -> Bool {
            guard userDefaults.openingUntilReview <= 0 else {
                return false
            }

            userDefaults.openingUntilReview = openingBeforeNextReviews

            if userHasAlreadyAnsweredYes {
                // If the user has already answered yes, we will directly present the SKStoreReviewController
                requestReview()
                return false
            } else {
                return true
            }
        }

    public func requestReview() {
        DispatchQueue.main.async {
            #if canImport(UIKit)
            if #available(iOS 14.0, *) {
                if let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            } else {
                SKStoreReviewController.requestReview()
            }
            #else
            SKStoreReviewController.requestReview()
            #endif
        }
    }
}
