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
