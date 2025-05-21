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

extension Int: Identifiable {
    public var id: Int {
        return self
    }
}

final class UTCollectionIdentity: XCTestCase {
    func testIntSameArraySameHash() {
        // GIVEN
        let lhsArray = [1, 2, 3, 4]
        let rhsArray = [1, 2, 3, 4]

        // WHEN
        let lhsId = lhsArray.collectionId()
        let rhsId = rhsArray.collectionId()

        // THEN
        XCTAssertEqual(lhsId, rhsId, "We expect the ids to be the same")
    }

    func testIntSameArraySameHashWithBase() {
        // GIVEN
        let lhsArray = [1, 2, 3, 4]
        let rhsArray = [1, 2, 3, 4]

        // WHEN
        let lhsId = lhsArray.collectionId(baseId: 10)
        let rhsId = rhsArray.collectionId(baseId: 10)

        // THEN
        XCTAssertEqual(lhsId, rhsId, "We expect the ids to be the same")
    }

    func testIntReversedArrayDifferentHash() {
        // GIVEN
        let lhsArray = [1, 2, 3, 4]
        let rhsArray = [1, 2, 3, 4].reversed()

        // WHEN
        let lhsId = lhsArray.collectionId()
        let rhsId = rhsArray.collectionId()

        // THEN
        XCTAssertNotEqual(lhsId, rhsId, "We expect the ids to not be the same")
    }

    func testIntDifferentArrayDifferentHash() {
        // GIVEN
        let lhsArray = [1, 2, 3, 4]
        let rhsArray = [1, 2, 3, 5]

        // WHEN
        let lhsId = lhsArray.collectionId()
        let rhsId = rhsArray.collectionId()

        // THEN
        XCTAssertNotEqual(lhsId, rhsId, "We expect the ids to not be the same")
    }

    func testIntDifferentArrayDifferentHashWithBase() {
        // GIVEN
        let lhsArray = [1, 2, 3, 4]
        let rhsArray = [1, 2, 3, 5]

        // WHEN
        let lhsId = lhsArray.collectionId(baseId: 10)
        let rhsId = rhsArray.collectionId(baseId: 10)

        // THEN
        XCTAssertNotEqual(lhsId, rhsId, "We expect the ids to not be the same")
    }

    func testIntDifferentArrayDifferentHashWithDifferentBase() {
        // GIVEN
        let lhsArray = [1, 2, 3, 4]
        let rhsArray = [1, 2, 3, 5]

        // WHEN
        let lhsId = lhsArray.collectionId(baseId: 10)
        let rhsId = rhsArray.collectionId(baseId: 11)

        // THEN
        XCTAssertNotEqual(lhsId, rhsId, "We expect the ids to not be the same")
    }
}
