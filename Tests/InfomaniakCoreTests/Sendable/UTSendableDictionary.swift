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

    func testRemoveAll() async {
        // GIVEN
        let collection = SendableDictionary<String, Int>()
        collection.setValue(1, for: "a")
        collection.setValue(2, for: "b")

        // WHEN
        let t = Task.detached {
            collection.removeAll()
        }

        _ = await t.result

        // THEN
        XCTAssertTrue(collection.values.isEmpty)
    }

    func testIterator() async {
        // GIVEN
        let collection = SendableDictionary<String, Int>()
        collection.setValue(1, for: "a")
        collection.setValue(2, for: "b")

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
        while let (key, value) = iterator.next() {
            isEmpty = false

            if key == "a" {
                XCTAssertEqual(value, 1)
            } else if key == "b" {
                XCTAssertEqual(value, 2)
            } else {
                XCTFail("unexpected key:\(key) value:\(value)")
            }
        }

        XCTAssertFalse(isEmpty, "the iterator is not supposed to be empty")
    }

    func testEnumerated() async {
        // GIVEN
        let collection = SendableDictionary<String, Int>()
        collection.setValue(1, for: "a")
        collection.setValue(2, for: "b")

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
        for (index, node) in collectionEnumerated {
            isEmpty = false

            let key = node.0
            let value = node.1

            if key == "a" {
                XCTAssertEqual(value, 1)
            } else if key == "b" {
                XCTAssertEqual(value, 2)
            } else {
                XCTFail("unexpected key:\(key) value:\(value) at index:\(index) ")
            }
        }

        XCTAssertFalse(isEmpty, "the iterator is not supposed to be empty")
    }
}
