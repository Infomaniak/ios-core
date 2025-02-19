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
    struct Keys: Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        static let legacyIsFirstLaunch = Keys(rawValue: "isFirstLaunch")
        static let currentUserId = Keys(rawValue: "currentUserId")
        static let appRestorationVersion = Keys(rawValue: "appRestorationVersion")
    }

    func key(_ key: Keys) -> String {
        return key.rawValue
    }
}

// MARK: - Public extension

public extension UserDefaults {
    var currentUserId: Int {
        get {
            return integer(forKey: key(.currentUserId))
        }
        set {
            set(newValue, forKey: key(.currentUserId))
        }
    }

    var legacyIsFirstLaunch: Bool {
        get {
            guard let isFirstLaunch = object(forKey: key(.legacyIsFirstLaunch)) as? Bool else {
                return true
            }

            return isFirstLaunch
        }
        set {
            set(newValue, forKey: key(.legacyIsFirstLaunch))
        }
    }

    var appRestorationVersion: Int? {
        get {
            return object(forKey: key(.appRestorationVersion)) as? Int
        }
        set {
            set(newValue, forKey: key(.appRestorationVersion))
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
