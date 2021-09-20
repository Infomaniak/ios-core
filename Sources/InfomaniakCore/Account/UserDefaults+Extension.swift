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

import Foundation

public extension UserDefaults {
    struct Keys {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        static let isFirstLaunch = Keys(rawValue: "isFirstLaunch")
        static let currentUserId = Keys(rawValue: "currentUserId")
    }

    func key(_ key: Keys) -> String {
        return key.rawValue
    }

    var isFirstLaunch: Bool {
        get {
            if object(forKey: key(.isFirstLaunch)) != nil {
                return bool(forKey: key(.isFirstLaunch))
            } else {
                return true
            }
        }
        set {
            set(newValue, forKey: key(.isFirstLaunch))
        }
    }

    var currentUserId: Int {
        get {
            return integer(forKey: key(.currentUserId))
        }
        set {
            set(newValue, forKey: key(.currentUserId))
        }
    }
}
