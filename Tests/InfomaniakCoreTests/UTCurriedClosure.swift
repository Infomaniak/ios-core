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
final class UTCurriedClosure: XCTestCase {
    func testAppendToClosure() {
        // GIVEN
        let expectationA = CountedFulfillmentTestExpectation(description: "Closure is called")
        let expectationB = CountedFulfillmentTestExpectation(description: "Closure is called")
        let expectations = [expectationA, expectationB]

        let a: SimpleClosure = { _ in
            XCTAssertEqual(expectationA.currentFulfillmentCount, 0, "expectationA should not be fulfilled")
            XCTAssertEqual(expectationB.currentFulfillmentCount, 0, "expectationB should not be fulfilled")
            expectationA.fulfill()
        }

        let b: SimpleClosure = { _ in
            XCTAssertEqual(expectationA.currentFulfillmentCount, 1, "expectationA should be fulfilled")
            XCTAssertEqual(expectationB.currentFulfillmentCount, 0, "expectationB should not be fulfilled")
            expectationB.fulfill()
        }

        // WHEN
        let computation = a + b
        let _ = computation~

        // THEN
        wait(for: expectations, timeout: 10.0)
    }

    func testAppendToClosure_3chain() {
        // GIVEN
        let expectationA = CountedFulfillmentTestExpectation(description: "Closure is called")
        let expectationB = CountedFulfillmentTestExpectation(description: "Closure is called")
        let expectationC = CountedFulfillmentTestExpectation(description: "Closure is called")
        let expectations = [expectationA, expectationB, expectationC]

        let a: SimpleClosure = { _ in
            XCTAssertEqual(expectationA.currentFulfillmentCount, 0, "expectationA should not be fulfilled")
            XCTAssertEqual(expectationB.currentFulfillmentCount, 0, "expectationB should not be fulfilled")
            XCTAssertEqual(expectationC.currentFulfillmentCount, 0, "expectationC should not be fulfilled")
            expectationA.fulfill()
        }

        let b: SimpleClosure = { _ in
            XCTAssertEqual(expectationA.currentFulfillmentCount, 1, "expectationA should be fulfilled")
            XCTAssertEqual(expectationB.currentFulfillmentCount, 0, "expectationB should not be fulfilled")
            XCTAssertEqual(expectationC.currentFulfillmentCount, 0, "expectationC should not be fulfilled")
            expectationB.fulfill()
        }

        let c: SimpleClosure = { _ in
            XCTAssertEqual(expectationA.currentFulfillmentCount, 1, "expectation should be fulfilled")
            XCTAssertEqual(expectationB.currentFulfillmentCount, 1, "expectation should be fulfilled")
            XCTAssertEqual(expectationC.currentFulfillmentCount, 0, "expectationC should not be fulfilled")
            expectationC.fulfill()
        }

        // WHEN
        let computation = a + b + c
        let _ = computation~

        // THEN
        wait(for: expectations, timeout: 10.0)
    }
}
