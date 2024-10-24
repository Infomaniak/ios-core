/*
 Infomaniak kDrive - iOS App
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

import Foundation
import InfomaniakCore

/// A public mock for the MCKChunkProvidable module
public final class MCKChunkProvidable: ChunkProvidable {
    var fileURL: URL
    var ranges: [DataRange]
    public init?(fileURL: URL, ranges: [DataRange]) {
        self.fileURL = fileURL
        self.ranges = ranges
    }

    // MARK: - IteratorProtocol

    public typealias Element = Data

    var nextCalled: Bool { nextCallCount > 0 }
    var nextCallCount = 0
    var nextClosure: (() -> Data?)?
    public func next() -> Data? {
        nextCallCount += 1
        if let nextClosure {
            let data = nextClosure()
            return data
        } else {
            return nil
        }
    }
}
