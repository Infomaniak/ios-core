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
final class UTDataStreamHasher: XCTestCase {
    func testStreamHash() {
        // GIVEN
        guard let payload = "Some payload to be used for hashing as a steam.".data(using: String.Encoding.utf8) else {
            XCTFail("Unexpected")
            return
        }

        let expectedSHA256 = "845ec75e4b7725f1738c93be49bc0dded938fa7ce420d69132301a6bf36e8878"

        let bytes = payload.reduce(into: [UInt8]()) { partialResult, byte in
            partialResult.append(byte)
        }

        XCTAssertEqual(bytes.count, 47, "Precondition on data length to be parsed")

        let stream = bytes.chunked(into: 4) // A 2d Array of bytes to mimic a stream of data
        XCTAssertEqual(stream.count, 12, "Precondition on stream to be parsed")

        let streamHasher = DataStreamHasher()

        // WHEN
        for buffer in stream {
            let data = Data(buffer)
            streamHasher.update(data)
        }

        streamHasher.finalize()

        // THEN
        guard let hash = streamHasher.digestString else {
            XCTFail("Not able to get a hash ")
            return
        }

        XCTAssertEqual(hash, expectedSHA256, "the hashes are expected to match")
    }

    func testStreamHashAgainstOneShotHash() {
        // GIVEN
        guard let payload = "Some payload to be used for hashing as a steam.".data(using: String.Encoding.utf8) else {
            XCTFail("Unexpected")
            return
        }

        // Hashing the data at once
        let oneShotHash = payload.SHA256DigestString

        let bytes = payload.reduce(into: [UInt8]()) { partialResult, byte in
            partialResult.append(byte)
        }

        XCTAssertEqual(bytes.count, 47, "Precondition on data length to be parsed")

        let stream = bytes.chunked(into: 4) // A 2d Array of bytes to mimic a stream of data
        XCTAssertEqual(stream.count, 12, "Precondition on stream to be parsed")

        let streamHasher = DataStreamHasher()

        // WHEN
        for buffer in stream {
            let data = Data(buffer)
            streamHasher.update(data)
        }

        streamHasher.finalize()

        // THEN
        guard let hash = streamHasher.digestString else {
            XCTFail("Not able to get a hash ")
            return
        }

        XCTAssertEqual(hash, oneShotHash, "the hashes are expected to match")
    }
}
