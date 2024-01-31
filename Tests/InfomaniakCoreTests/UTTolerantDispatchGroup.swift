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

@testable import InfomaniakCore
import XCTest

extension DispatchQoS: CaseIterable {
    public static var allCases: [DispatchQoS] {
        [.background, .utility, .default, .userInitiated, .userInteractive, .unspecified]
    }
}

final class UTTolerantDispatchGroup: XCTestCase {
    func testCanInit() {
        // WHEN
        let dispatchGroup = TolerantDispatchGroup()

        // THEN
        XCTAssertNotNil(dispatchGroup)
    }

    func testDefaultPriorityIsHigh() {
        // WHEN
        let dispatchGroup = TolerantDispatchGroup()

        // THEN
        XCTAssertNotNil(dispatchGroup)
        XCTAssertEqual(dispatchGroup.syncQueue.qos, DispatchQoS.userInitiated, "default constructor should have default priority")
    }

    func testPriorityAnyIsSet() {
        // GIVEN
        guard let expectedQoS = DispatchQoS.allCases.randomElement() else {
            XCTFail("unexpected")
            return
        }

        // WHEN
        let dispatchGroup = TolerantDispatchGroup(qos: expectedQoS)

        // THEN
        XCTAssertNotNil(dispatchGroup)
        XCTAssertEqual(dispatchGroup.syncQueue.qos, expectedQoS, "QoS should match")
    }
}
