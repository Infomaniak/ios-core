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
final class UTCompression: XCTestCase {
    func testCompression() {
        // GIVEN
        let lowEntropy = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        let lowEntropyData = lowEntropy.data(using: .utf8)!
        
        // WHEN
        guard let highEntropy = lowEntropy.compressed() else {
            XCTFail("Unexpected")
            return
        }
        
        // THEN
        XCTAssertLessThan(highEntropy.count, lowEntropyData.count, "Compressed message should be smaller")
    }

    func testCompressionDecompression() {
        // GIVEN
        let lowEntropy = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        
        // WHEN
        guard let highEntropy = lowEntropy.compressed() else {
            XCTFail("Unexpected")
            return
        }
        
        let decompressedString = highEntropy.decompressedString()
        
        // THEN
        XCTAssertEqual(lowEntropy, decompressedString)
    }
}
