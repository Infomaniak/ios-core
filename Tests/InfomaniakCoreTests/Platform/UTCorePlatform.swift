/*
 Infomaniak Core - iOS
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

import InfomaniakCore
import XCTest

// MARK: - appVersionLabel

#if canImport(UIKit)

@available(iOS 13.0, *) final class UTCorePlatform: XCTestCase {
    func testVersionLabel_ios() {
        // GIVEN
        let expectedPrefix = "xctest iOS version"

        // WHEN
        let versionLabel = CorePlatform.appVersionLabel(fallbackAppName: "xctest")

        // THEN
        XCTAssertTrue(versionLabel.hasPrefix(expectedPrefix), "wrong text, got :\(versionLabel)")
    }
}

#else

@available(macOS 10.15, *) final class UTCorePlatform: XCTestCase {
    func testVersionLabel_mac() {
        // GIVEN
        let expectedPrefix = "xctest macOS version"

        // WHEN
        let versionLabel = CorePlatform.appVersionLabel(fallbackAppName: "xctest")

        // THEN
        XCTAssertTrue(versionLabel.hasPrefix(expectedPrefix), "wrong text, got :\(versionLabel)")
    }
}

#endif
