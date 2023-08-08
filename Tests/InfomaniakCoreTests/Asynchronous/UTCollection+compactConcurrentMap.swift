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
final class UTConcurrentCompactMap: XCTestCase {
    private enum DomainError: Error {
        case some
    }

    // MARK: - concurrentCompactMap

    func testConcurrentCompactMapToArray() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        let result: [Int] = await collectionToProcess.concurrentCompactMap { item in
            // We arbitrarily remove elements
            if item % 10 == 0 {
                return nil
            }
            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        XCTAssertEqual(result.count, collectionToProcess.count - 6)
    }

    func testConcurrentCompactMapToArraySlice() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 200)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 50]

        // WHEN
        let result: [Int] = await collectionSlice.concurrentCompactMap { item in
            // We arbitrarily remove elements
            if item % 10 == 0 {
                return nil
            }

            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        XCTAssertEqual(result.count, collectionSlice.count - 6)
    }

    func testConcurrentCompactMapToDictionary() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        let result: [(String, Int)] = await dictionaryToProcess.concurrentCompactMap { item in
            // We arbitrarily remove elements
            if item.value % 10 == 0 {
                return nil
            }

            let newItem = (item.key, item.value * 10)
            return newItem
        }

        // THEN

        // NOTE: Not checking for order, since this is a Dictionary

        XCTAssertEqual(result.count, dictionaryToProcess.count - 6)

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

    // MARK: - concurrentCompactMap throwing sleep

    func testConcurrentCompactMapToArrayThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let result: [Int] = try await collectionToProcess.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item % 10 == 0 {
                    return nil
                }

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

            XCTAssertEqual(result.count, collectionToProcess.count - 6)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentCompactMapToArraySliceThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 200)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 50]

        // WHEN
        do {
            let result: [Int] = try await collectionSlice.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item % 10 == 0 {
                    return nil
                }

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

            XCTAssertEqual(result.count, collectionSlice.count - 6)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentCompactMapToDictionaryThrowingSleep() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let result: [(String, Int)] = try await dictionaryToProcess.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item.value % 10 == 0 {
                    return nil
                }

                let newItem = (item.key, item.value * 10)
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)
                return newItem
            }

            // THEN

            // NOTE: Not checking for order, since this is a Dictionary

            XCTAssertEqual(result.count, dictionaryToProcess.count - 6)

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

    // MARK: - concurrentCompactMap throwing computation

    func testConcurrentCompactMapToArrayThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _: [Int] = try await collectionToProcess.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item % 3 == 0 {
                    return nil
                }

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

    func testConcurrentCompactMapToArraySliceThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _: [Int] = try await collectionSlice.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item % 3 == 0 {
                    return nil
                }

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

    func testConcurrentCompactMapToDictionaryThrowingComputation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _: [(String, Int)] = try await dictionaryToProcess.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item.value % 3 == 0 {
                    return nil
                }

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

    // MARK: - concurrentCompactMap throwing cancellation

    func testConcurrentCompactMapToArrayThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _: [Int] = try await collectionToProcess.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item % 3 == 0 {
                    return nil
                }

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

    func testConcurrentCompactMapToArraySliceThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _: [Int] = try await collectionSlice.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item % 3 == 0 {
                    return nil
                }

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

    func testConcurrentCompactMapToDictionaryThrowingCancellation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _: [(String, Int)] = try await dictionaryToProcess.concurrentCompactMap { item in
                // We arbitrarily remove elements
                if item.value % 3 == 0 {
                    return nil
                }

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
    
    func testConcurrentCompactMapNonNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: Array<Int?> = [1, nil, 3, 4, nil, 5]

        let result: [Int] = await collectionToProcess.concurrentCompactMap { item in
            guard let item else {
                return nil
            }
            
            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }
        
        // Expecting same behaviour than a standard lib compact map
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result.count, collectionToProcess.compactMap{$0}.count)
    }
    
    
    // Not something useful to do, but consistent.
    func testConcurrentCompactMapNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: Array<Int?> = [1, nil, 3, 4, nil, 5]

        let result: [Int?] = await collectionToProcess.concurrentCompactMap { item in
            guard let item else {
                return nil
            }
            
            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            guard let item else {
                XCTFail("Not expecting a nil result inside the result of a flat map")
                return partialResult
            }
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        // Expecting same behaviour than a standard lib compact map
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result.count, collectionToProcess.compactMap{$0}.count)
    }
    
    
}
