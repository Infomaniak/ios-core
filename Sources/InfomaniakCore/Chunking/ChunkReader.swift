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

@available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
public final class ChunkReader: Sendable {
    let fileHandle: FileHandlable

    deinit {
        do {
            // For the sake of consistency
            try fileHandle.close()
        } catch {}
    }

    public init?(fileURL: URL) {
        do {
            fileHandle = try FileHandle(forReadingFrom: fileURL)
        } catch {
            return nil
        }
    }

    /// Internal testing method
    init(mockedHandlable: FileHandlable) {
        fileHandle = mockedHandlable
    }

    public func readChunk(range: DataRange) throws -> Data? {
        let offset = range.lowerBound
        try fileHandle.seek(toOffset: offset)

        let byteCount = Int(range.upperBound - range.lowerBound) + 1
        let chunk = try fileHandle.read(upToCount: byteCount)
        return chunk
    }
}
