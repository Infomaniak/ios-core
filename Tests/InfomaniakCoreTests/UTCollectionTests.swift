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

final class UTCollectionTests: XCTestCase {
    func testSafeIndexSuccess() {
        // GIVEN
        let shortArray = [1]

        // WHEN
        let fetched = shortArray[safe: 0]

        // THEN
        XCTAssertEqual(fetched, 1)
    }

    func testSafeIndexNil() {
        // GIVEN
        let shortArray = [1]

        // WHEN
        let fetched = shortArray[safe: 1]

        // THEN
        XCTAssertNil(fetched)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class UTSendableArray: XCTestCase {
    func testInsertSubscript() async {
        // GIVEN
        let collection = SendableArray<String>()

        // WHEN
        let t = Task.detached {
            collection[0] = "a"
            collection[1] = "b"
            collection[2] = "c"
        }

        _ = await t.result

        // THEN
        XCTAssertEqual(collection.count, 3)
    }

    func testInsert() async {
        // GIVEN
        let collection = SendableArray<String>()

        // WHEN
        let t = Task.detached {
            collection.append("a")
            collection.append("b")
        }

        _ = await t.result

        // THEN
        XCTAssertEqual(collection.count, 2)
    }

    func testUpdate() async {
        // GIVEN
        let collection = SendableArray<String>()

        // WHEN
        let t = Task.detached {
            collection.append("a")
            collection[0] = "b"
            collection[1] = "c"
        }

        _ = await t.result

        // THEN
        XCTAssertEqual(collection.count, 2)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class UTSendableDictionary: XCTestCase {
    func testInsertSubscript() async {
        // GIVEN
        let collection = SendableDictionary<String, Int>()

        // WHEN
        let t = Task.detached {
            collection["a"] = 1
            collection["b"] = 2
        }

        _ = await t.result

        // THEN
        XCTAssertEqual(collection.count, 2)
    }

    func testInsert() async {
        // GIVEN
        let collection = SendableDictionary<String, Int>()

        // WHEN
        let t = Task.detached {
            collection.setValue(1, for: "a")
            collection.setValue(2, for: "b")
        }

        _ = await t.result

        // THEN
        XCTAssertEqual(collection.count, 2)
    }
}
