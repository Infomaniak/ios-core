/*
 Infomaniak kDrive - iOS App
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

import Foundation
@testable import InfomaniakCore
import XCTest

/// Unit Tests of the ChunkReader
@available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
final class UTChunkReader: XCTestCase {
    // MARK: - readChunk(range:)

    func testReadChunk_validChunk() throws {
        // GIVEN
        let range: DataRange = 0 ... 1
        let mckFileHandle = MCKFileHandlable()
        mckFileHandle.readUpToCountClosure = { _ in Data() }
        mckFileHandle.seekToOffsetClosure = { index in
            XCTAssertEqual(index, range.lowerBound)
        }

        let chunkProvider = ChunkReader(mockedHandlable: mckFileHandle)

        // WHEN
        do {
            let chunk = try chunkProvider.readChunk(range: range)
            XCTAssertNotNil(chunk)
        } catch {
            XCTFail("Unexpected :\(error)")
            return
        }

        // THEN
        XCTAssertEqual(mckFileHandle.seekToOffsetCallCount, 1)
        XCTAssertEqual(mckFileHandle.readUpToCountCallCount, 1)
    }

    func testReadChunk_throwErrorOnSeek() throws {
        // GIVEN
        let range: DataRange = 0 ... 1
        let mckFileHandle = MCKFileHandlable()
        mckFileHandle.readUpToCountClosure = { _ in Data() }
        mckFileHandle.seekToOffsetError = NSError(domain: "k", code: 1337)

        let chunkProvider = ChunkReader(mockedHandlable: mckFileHandle)

        // WHEN
        do {
            _ = try chunkProvider.readChunk(range: range)
            XCTFail("Unexpected")
            return
        } catch {
            guard (error as NSError).code == 1337 else {
                XCTFail("Unexpected")
                return
            }
            // all good
        }

        // THEN
        XCTAssertEqual(mckFileHandle.seekToOffsetCallCount, 1)
        XCTAssertEqual(mckFileHandle.readUpToCountCallCount, 0)
    }

    func testReadChunk_throwErrorOnRead() throws {
        // GIVEN
        let range: DataRange = 0 ... 1
        let mckFileHandle = MCKFileHandlable()
        mckFileHandle.readUpToCountClosure = { _ in Data() }
        mckFileHandle.readUpToCountError = NSError(domain: "k", code: 1337)

        let chunkProvider = ChunkReader(mockedHandlable: mckFileHandle)

        // WHEN
        do {
            _ = try chunkProvider.readChunk(range: range)
            XCTFail("Unexpected")
            return
        } catch {
            guard (error as NSError).code == 1337 else {
                XCTFail("Unexpected")
                return
            }
            // all good
        }

        // THEN
        XCTAssertEqual(mckFileHandle.seekToOffsetCallCount, 1)
        XCTAssertEqual(mckFileHandle.readUpToCountCallCount, 1)
    }
}
