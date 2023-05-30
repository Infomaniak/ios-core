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
final class UTParallelTaskMapper: XCTestCase {
    func testAsyncMap() async {
        // GIVEN
        let taskMapper = ParallelTaskMapper()
        let collectionToProcess = Array(0 ... 15)

        // WHEN
        do {
            let result = try await taskMapper.map(collection: collectionToProcess) { item in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                return item * 10
            }

            // THEN
            // We check order is preserved
            result.reduce(-1) { partialResult, item in
                guard let item = item else {
                    fatalError("Unexpected")
                }
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

        } catch {
            XCTFail("Unexpected")
            return
        }
    }
}
