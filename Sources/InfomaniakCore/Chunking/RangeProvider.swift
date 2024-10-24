/*
 Infomaniak kDrive - iOS App
 Copyright (C) 2021 Infomaniak Network SA

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

/// A range of Bytes on a `Data` buffer
///   - start: start byte index, first index at 0 by convention.
///   - end: end byte index, last index at fileSize -1 by convention.
public typealias DataRange = ClosedRange<UInt64>

/// Something that can provide a sequence of ranges where the file should be split if necessary.
public protocol RangeProvidable {
    /// Computes and return all the contiguous ranges for a file at the moment of calling.
    ///
    /// Result may change over time if file is modified in between calls.
    /// Throws if file too large or too small, also if file system issue.
    /// Minimum size support is one byte (low bound == high bound)
    var allRanges: [DataRange] { get throws }

    /// Return the file size in bytes at the moment of calling.
    var fileSize: UInt64 { get throws }
}

@frozen public struct RangeProvider: RangeProvidable {
    @frozen public struct Config {
        public let chunkMinSize: UInt64
        public let chunkMaxSizeClient: UInt64
        public let chunkMaxSizeServer: UInt64
        public let optimalChunkCount: UInt64
        public let maxTotalChunks: UInt64
        public let minTotalChunks: UInt64

        public let fileMaxSizeClient: UInt64
        public let fileMaxSizeServer: UInt64

        public init(
            chunkMinSize: UInt64,
            chunkMaxSizeClient: UInt64,
            chunkMaxSizeServer: UInt64,
            optimalChunkCount: UInt64,
            maxTotalChunks: UInt64,
            minTotalChunks: UInt64
        ) {
            self.chunkMinSize = chunkMinSize
            self.chunkMaxSizeClient = chunkMaxSizeClient
            self.chunkMaxSizeServer = chunkMaxSizeServer
            self.optimalChunkCount = optimalChunkCount
            self.maxTotalChunks = maxTotalChunks
            self.minTotalChunks = minTotalChunks

            fileMaxSizeClient = maxTotalChunks * chunkMaxSizeClient
            fileMaxSizeServer = maxTotalChunks * chunkMaxSizeServer
        }
    }

    enum ErrorDomain: Error {
        /// Unable to read file system metadata
        case UnableToReadFileAttributes

        /// file is over the supported size
        case FileTooLarge

        /// We ask for chunks that do not make sense
        case ChunkedSizeLargerThanSourceFile

        /// At least one chunk is expected
        case IncorrectTotalChunksCount

        /// A non zero size is expected
        case IncorrectChunkSize
    }

    /// The internal methods split into another type, make testing easier
    var guts: RangeProviderGutsable

    let config: Config

    public init(fileURL: URL, config: Config) {
        guts = RangeProviderGuts(fileURL: fileURL, config: config)
        self.config = config
    }

    public var fileSize: UInt64 {
        get throws {
            let size = try guts.readFileByteSize()
            return size
        }
    }

    public var allRanges: [DataRange] {
        get throws {
            let size = try fileSize

            // Check for files too large to be processed by mobile app or the server
            guard size < config.fileMaxSizeClient,
                  size < config.fileMaxSizeServer else {
                // TODO: notify Sentry
                throw ErrorDomain.FileTooLarge
            }

            let preferredChunkSize = guts.preferredChunkSize(for: size)

            // Make sure an empty file resolves to one chunk
            let totalChunksCount = max(size / max(preferredChunkSize, 1), 1)

            let ranges = try guts.buildRanges(fileSize: size,
                                              totalChunksCount: totalChunksCount,
                                              chunkSize: preferredChunkSize)

            return ranges
        }
    }
}
