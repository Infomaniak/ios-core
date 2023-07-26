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
final class UTConcurrentMap: XCTestCase {
    private enum DomainError: Error {
        case some
    }

    // MARK: - concurrentMap

    func testConcurrentMapToArray() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        let result = await collectionToProcess.concurrentMap { item in
            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        XCTAssertEqual(result.count, collectionToProcess.count)
    }

    func testConcurrentMapToArraySlice() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        let result = await collectionSlice.concurrentMap { item in
            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        XCTAssertEqual(result.count, collectionSlice.count)
    }

    func testConcurrentMapToDictionary() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        let result = await dictionaryToProcess.concurrentMap { item in
            let newItem = (item.key, item.value * 10)
            return newItem
        }

        // THEN

        // NOTE: Not checking for order, since this is a Dictionary

        XCTAssertEqual(result.count, dictionaryToProcess.count)

        for (_, tuple) in result.enumerated() {
            let key = tuple.0
            guard let intKey = Int(key) else {
                XCTFail("Unexpected")
                return
            }

            let value = tuple.1
            XCTAssertEqual(intKey * 10, value, "expecting the computation to have happened")
        }
    }

    // MARK: - concurrentMap throwing sleep

    func testConcurrentMapToArrayThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let result = try await collectionToProcess.concurrentMap { item in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionToProcess.count)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentMapToArraySliceThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let result = try await collectionSlice.concurrentMap { item in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionSlice.count)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentMapToDictionaryThrowingSleep() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let result = try await dictionaryToProcess.concurrentMap { item in
                let newItem = (item.key, item.value * 10)
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)
                return newItem
            }

            // THEN

            // NOTE: Not checking for order, since this is a Dictionary

            XCTAssertEqual(result.count, dictionaryToProcess.count)

            for (_, tuple) in result.enumerated() {
                let key = tuple.0
                guard let intKey = Int(key) else {
                    XCTFail("Unexpected")
                    return
                }

                let value = tuple.1
                XCTAssertEqual(intKey * 10, value, "expecting the computation to have happened")
            }

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    // MARK: - concurrentMap throwing computation

    func testConcurrentMapToArrayThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _ = try await collectionToProcess.concurrentMap { item in
                if item == 10 {
                    throw DomainError.some
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToArraySliceThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _ = try await collectionSlice.concurrentMap { item in
                if item == 10 {
                    throw DomainError.some
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToDictionaryThrowingComputation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _ = try await dictionaryToProcess.concurrentMap { item in
                let newItem = (item.key, item.value * 10)

                if item.value == 10 {
                    throw DomainError.some
                }

                return newItem
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    // MARK: - concurrentMap throwing cancellation

    func testConcurrentMapToArrayThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _ = try await collectionToProcess.concurrentMap { item in
                if item == 10 {
                    throw CancellationError()
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToArraySliceThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _ = try await collectionSlice.concurrentMap { item in
                if item == 10 {
                    throw CancellationError()
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToDictionaryThrowingCancellation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _ = try await dictionaryToProcess.concurrentMap { item in
                let newItem = (item.key, item.value * 10)

                if item.value == 10 {
                    throw CancellationError()
                }

                return newItem
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }
    
    // MARK: - nullability of output types

    func testConcurrentMapNonNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: Array<Int> = [1, 2, 3, 4, 5]

        let result: Array<Int> = await collectionToProcess.concurrentMap { someInt in
            return someInt + 1
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        // Expecting same behaviour as a standard lib map
        XCTAssertEqual(result.count, collectionToProcess.count)
    }
    
    func testConcurrentMapNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: Array<Int?> = [1, nil, 3, 4, nil, 5]

        let result: Array<Int?> = await collectionToProcess.concurrentMap { someInt in
            guard let someInt else {
                return nil
            }
            
            return someInt + 1
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            guard let item else {
                // Ok to find a nil here
                return partialResult
            }
            
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        // Expecting same behaviour as a standard lib map, preserving nullable in result.
        XCTAssertEqual(result.count, collectionToProcess.count)
    }
}
