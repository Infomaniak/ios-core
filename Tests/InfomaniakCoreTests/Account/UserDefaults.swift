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

import InfomaniakCore
import XCTest

final class UTUserDefaults: XCTestCase {
    func testCurrentUserId() {
        // GIVEN
        let userDefaults = UserDefaults()
        userDefaults.currentUserId = 1337

        // WHEN
        let currentUserId = userDefaults.currentUserId

        // THEN
        XCTAssertEqual(currentUserId, 1337)
    }

    func testLegacyIsFirstLaunch() {
        // GIVEN
        let userDefaults = UserDefaults()
        userDefaults.legacyIsFirstLaunch = true

        // WHEN
        let legacyIsFirstLaunch = userDefaults.legacyIsFirstLaunch

        // THEN
        XCTAssertEqual(legacyIsFirstLaunch, true)
    }

    func testAppRestorationVersion() {
        // GIVEN
        let userDefaults = UserDefaults()
        userDefaults.appRestorationVersion = 1337

        // WHEN
        let appRestorationVersion = userDefaults.appRestorationVersion

        // THEN
        XCTAssertEqual(appRestorationVersion, 1337)
    }
}
