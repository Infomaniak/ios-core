/*
 Infomaniak Core - iOS
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

/// A generic async/await accumulator, order preserving.
///
/// This is a thread safe actor.
/// It is backed by a fix length array, size defined at init.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public actor ArrayAccumulator<T> {
    /// Local Error Domain
    public enum ErrorDomain: Error {
        case outOfBounds
    }

    /// A buffer array
    private var buffer: [T?]

    /// Init an ArrayAccumulator
    /// - Parameters:
    ///   - count: The count of items in the accumulator
    ///   - wrapping: The type of the content wrapped in an array
    public init(count: Int, wrapping: T.Type) {
        buffer = [T?](repeating: nil, count: count)
    }

    /// Set an item at a specified index
    /// - Parameters:
    ///   - item: the item to be stored
    ///   - index: The index where we store the item
    public func set(item: T?, atIndex index: Int) throws {
        guard index < buffer.count else {
            throw ErrorDomain.outOfBounds
        }
        buffer[index] = item
    }

    /// The accumulated ordered nullable content at the time of calling
    /// - Returns: The ordered nullable content at the time of calling
    public var accumulation: [T?] {
        return buffer
    }

    /// The accumulated ordered result at the time of calling. Nil values are removed.
    /// - Returns: The ordered result at the time of calling. Nil values are removed.
    public var compactAccumulation: [T] {
        return buffer.compactMap { $0 }
    }
}
