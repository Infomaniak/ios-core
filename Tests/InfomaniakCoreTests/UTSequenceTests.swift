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
final class UTSequenceTests: XCTestCase {
    private func someAsyncFunc(input: Int) async -> Bool {
        try! await Task.sleep(nanoseconds: 100)
        return input > 2
    }

    func testAsyncMap() async {
        // GIVEN
        let array = [1, 2, 3, 4, 5]

        // WHEN
        let fetched = await array.asyncMap { await someAsyncFunc(input: $0) }

        // THEN
        XCTAssertEqual(fetched, [false, false, true, true, true])
    }

    func testAsyncForEach() async {
        // GIVEN
        let array = [1, 2, 3, 4, 5]
        var callCount = 0

        // WHEN
        await array.asyncForEach { _ in
            try! await Task.sleep(nanoseconds: 100)
            callCount += 1
        }

        // THEN
        XCTAssertEqual(array.count, callCount)
    }
}
