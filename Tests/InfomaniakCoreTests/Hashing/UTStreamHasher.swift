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

import CryptoKit
import InfomaniakCore
import XCTest

final class UTStreamHasher: XCTestCase {
    // MARK: - SHA256

    func testStreamHash256() {
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

        let streamHasher = StreamHasher<SHA256>()

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

    func testStreamHashAgainstOneShotHash256() {
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

        let streamHasher = StreamHasher<SHA256>()

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

    // MARK: - SHA512

    func testStreamHash512() {
        // GIVEN
        guard let payload = "Some payload to be used for hashing as a steam.".data(using: String.Encoding.utf8) else {
            XCTFail("Unexpected")
            return
        }

        let expectedSHA512 =
            "1d1692405c2eb2f819e9f65f03a9ca4be685153dbc70c4d7489623115aa56f49cf1ce7b9c260ac0ce6d287fb3cb2f8db06940a08a872de6724a80a7ea5505ee8"

        let bytes = payload.reduce(into: [UInt8]()) { partialResult, byte in
            partialResult.append(byte)
        }

        XCTAssertEqual(bytes.count, 47, "Precondition on data length to be parsed")

        let stream = bytes.chunked(into: 4) // A 2d Array of bytes to mimic a stream of data
        XCTAssertEqual(stream.count, 12, "Precondition on stream to be parsed")

        let streamHasher = StreamHasher<SHA512>()

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

        XCTAssertEqual(hash, expectedSHA512, "the hashes are expected to match")
    }

    func testStreamHashAgainstOneShotHash512() {
        // GIVEN
        guard let payload = "Some payload to be used for hashing as a steam.".data(using: String.Encoding.utf8) else {
            XCTFail("Unexpected")
            return
        }

        // Hashing the data at once
        let oneShotHash = payload.SHA512DigestString

        let bytes = payload.reduce(into: [UInt8]()) { partialResult, byte in
            partialResult.append(byte)
        }

        XCTAssertEqual(bytes.count, 47, "Precondition on data length to be parsed")

        let stream = bytes.chunked(into: 4) // A 2d Array of bytes to mimic a stream of data
        XCTAssertEqual(stream.count, 12, "Precondition on stream to be parsed")

        let streamHasher = StreamHasher<SHA512>()

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
