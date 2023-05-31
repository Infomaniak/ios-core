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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class UTArrayAccumulator: XCTestCase {
    func testAllGood() async {
        // GIVEN
        let expectedCount = 5
        let accumulator = ArrayAccumulator(count: expectedCount, wrapping: Int.self)

        // WHEN
        try? await accumulator.set(item: 3, atIndex: 1)
        try? await accumulator.set(item: 1, atIndex: 0)

        // THEN
        let accumulated = await accumulator.accumulation
        XCTAssertEqual(accumulated.count, expectedCount)

        let compactAccumulated = await accumulator.compactAccumulation
        XCTAssertEqual(compactAccumulated.count, 2)

        XCTAssertEqual(compactAccumulated[0], 1)
        XCTAssertEqual(compactAccumulated[1], 3)
    }

    func testOutOfBounds() async {
        // GIVEN
        let expectedCount = 5
        let accumulator = ArrayAccumulator(count: expectedCount, wrapping: String.self)

        // WHEN
        do {
            try await accumulator.set(item: "aa", atIndex: expectedCount)

            // THEN
            XCTFail("Unexpected")
        } catch {
            XCTAssertEqual(error as! ArrayAccumulator<String>.ErrorDomain, ArrayAccumulator<String>.ErrorDomain.outOfBounds)
        }
    }

    func testBoundZero() async {
        // GIVEN
        let expectedCount = 5
        let accumulator = ArrayAccumulator(count: expectedCount, wrapping: String.self)

        // WHEN
        do {
            try await accumulator.set(item: "aa", atIndex: 0)

            // THEN
            let resultCount = await accumulator.compactAccumulation.count
            XCTAssertEqual(resultCount, 1)
        } catch {
            XCTFail("Unexpected")
        }
    }

    func testBoundLast() async {
        // GIVEN
        let expectedCount = 5
        let accumulator = ArrayAccumulator(count: expectedCount, wrapping: String.self)

        // WHEN
        do {
            try await accumulator.set(item: "aa", atIndex: expectedCount - 1)

            // THEN
            let resultCount = await accumulator.compactAccumulation.count
            XCTAssertEqual(resultCount, 1)
        } catch {
            XCTFail("Unexpected")
        }
    }
}
