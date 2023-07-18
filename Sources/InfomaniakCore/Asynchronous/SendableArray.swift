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

import Foundation

/// A thread safe Array wrapper that does not require `await`. Conforms to Sendable.
///
/// Useful when dealing with UI.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class SendableArray<T>: @unchecked Sendable {
    /// Serial locking queue
    let lock = DispatchQueue(label: "com.infomaniak.core.SendableArray.lock")

    /// Internal collection
    private(set) var content = [T]()

    public init() {
        // META: keep SonarCloud happy
    }

    public var count: Int {
        var buffer: Int!
        lock.sync {
            buffer = content.count
        }

        return buffer
    }

    public var values: [T] {
        var buffer: [T]!
        lock.sync {
            buffer = content
        }

        return buffer
    }

    public func append(_ newElement: T) {
        lock.sync {
            content.append(newElement)
        }
    }

    public func append(contentsOf collection: any Sequence<T>) {
        lock.sync {
            content.append(contentsOf: collection)
        }
    }

    public func popLast() -> T? {
        var buffer: T?
        lock.sync {
            buffer = content.popLast()
        }

        return buffer
    }

    public func insert(_ item: T, at index: Int) {
        lock.sync {
            content.insert(item, at: index)
        }
    }

    public var isEmpty: Bool {
        var isEmpty: Bool!
        lock.sync {
            isEmpty = content.isEmpty
        }
        return isEmpty
    }

    /// Bracket get / set pattern
    public subscript(_ index: Int) -> T? {
        get {
            var buffer: T?
            lock.sync {
                buffer = content[index]
            }
            return buffer
        }
        set {
            guard let newValue else {
                return
            }

            lock.sync {
                guard content[safe: index] != nil else {
                    content.insert(newValue, at: index)
                    return
                }
                content[index] = newValue
            }
        }
    }
}
