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

public extension UserDefaults {
    struct Keys {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        // TODO: Clean hotfix
        static let legacyIsFirstLaunch = Keys(rawValue: "isFirstLaunch")
        static let currentUserId = Keys(rawValue: "currentUserId")
    }

    func key(_ key: Keys) -> String {
        return key.rawValue
    }

    var currentUserId: Int {
        get {
            return integer(forKey: key(.currentUserId))
        }
        set {
            set(newValue, forKey: key(.currentUserId))
        }
    }

    // TODO: Clean hotfix
    var legacyIsFirstLaunch: Bool {
        get {
            if object(forKey: key(.legacyIsFirstLaunch)) != nil {
                return bool(forKey: key(.legacyIsFirstLaunch))
            } else {
                return true
            }
        }
        set {
            set(newValue, forKey: key(.legacyIsFirstLaunch))
        }
    }
}

// MARK: - Internal extension

extension UserDefaults.Keys {
    static let launchCounter = UserDefaults.Keys(rawValue: "launchCounter")
}

extension UserDefaults {
    var launchCounter: Int {
        get {
            return integer(forKey: key(.launchCounter))
        }
        set {
            set(newValue, forKey: key(.launchCounter))
        }
    }
}
