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

/// Something that builds chunks and provide them with an iterator.
public protocol ChunkProvidable: IteratorProtocol {
    init?(fileURL: URL, ranges: [DataRange])
}

/// Something that can chunk a file part by part, in memory, given specified ranges.
///
/// Memory considerations: Max memory use ≈sizeOf(one chunk). So from 1Mb to 50Mb
/// Thread safety: Not thread safe
///
@available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
public final class ChunkProvider: ChunkProvidable {
    public typealias Element = Data

    let chunkReader: ChunkReader

    var ranges: [DataRange]

    public init?(fileURL: URL, ranges: [DataRange]) {
        self.ranges = ranges

        guard let chunkReader = ChunkReader(fileURL: fileURL) else {
            return nil
        }

        self.chunkReader = chunkReader
    }

    /// Internal testing method
    init(mockedHandlable: FileHandlable, ranges: [DataRange]) {
        self.ranges = ranges
        chunkReader = ChunkReader(mockedHandlable: mockedHandlable)
    }

    /// Will provide chunks one by one, using the IteratorProtocol
    /// Starting by the first range available.
    public func next() -> Data? {
        guard !ranges.isEmpty else {
            return nil
        }

        let range = ranges.removeFirst()

        do {
            let chunk = try chunkReader.readChunk(range: range)
            return chunk
        } catch {
            return nil
        }
    }
}

/// Print the FileHandle shows the current offset
extension FileHandle {
    override open var description: String {
        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            let superDescription = super.description

            let offsetString: String
            do {
                let offset = try offset()
                offsetString = "\(offset)"
            } catch {
                offsetString = "\(error)"
            }

            let buffer = """
            <\(superDescription)>
            <offset:\(offsetString)>
            """

            return buffer
        } else {
            return super.description
        }
    }
}
