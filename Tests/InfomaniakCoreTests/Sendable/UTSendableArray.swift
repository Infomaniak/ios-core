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

    func testRemoveAll() async {
        // GIVEN
        let collection = SendableArray<String>()
        collection.append("a")
        collection.append("b")

        // WHEN
        let t = Task.detached {
            collection.removeAll()
        }

        _ = await t.result

        // THEN
        XCTAssertTrue(collection.isEmpty)
    }

    func testRemoveAllWhere() async {
        // GIVEN
        let collection = SendableArray<String>()
        collection.append("a")
        collection.append("b")
        collection.append("c")

        // WHEN
        let t = Task.detached {
            collection.removeAll(where: { $0 == "b" })
        }

        _ = await t.result

        // THEN
        XCTAssertFalse(collection.values.contains("b"))
    }
    
    func testIterator() async {
        // GIVEN
        let collection = SendableArray<String>()
        collection.append("a")
        collection.append("b")

        var iterator = collection.makeIterator()

        // WHEN
        // We remove all items in the collection
        let t = Task.detached {
            collection.removeAll()
        }

        await t.finish()

        // THEN
        XCTAssertTrue(collection.values.isEmpty, "The collection is expected to be empty")

        // We can work with the captured enumeration
        var isEmpty = true
        while let value = iterator.next() {
            isEmpty = false

            if value == "a" || value == "b" {
                // OK
            } else {
                XCTFail("unexpected value:\(value)")
            }
        }

        XCTAssertFalse(isEmpty, "the iterator is not supposed to be empty")
    }

    func testEnumerated() async {
        // GIVEN
        let collection = SendableArray<String>()
        collection.append("a")
        collection.append("b")

        let collectionEnumerated = collection.enumerated()

        // WHEN
        // We remove all items in the collection
        let t = Task.detached {
            collection.removeAll()
        }

        await t.finish()

        // THEN
        XCTAssertTrue(collection.values.isEmpty, "The collection is expected to be empty")

        // We can work with the captured enumeration
        var isEmpty = true
        for (index, value) in collectionEnumerated {
            isEmpty = false

            if value == "a" || value == "b" {
                // OK
            } else {
                XCTFail("unexpected value:\(value) at index:\(index)")
            }
        }

        XCTAssertFalse(isEmpty, "the iterator is not supposed to be empty")
    }
}
