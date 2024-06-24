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
/// Please prefer using first party structured concurrency. Use this for prototyping or dealing with race conditions.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class SendableArray<T>: @unchecked Sendable, Sequence {
    /// Serial locking queue
    let lock = DispatchQueue(label: "com.infomaniak.core.SendableArray.lock")

    /// Internal collection
    private(set) var content: [T]

    public init(content: [T] = [T]()) {
        self.content = content
    }

    public var count: Int {
        lock.sync {
            return content.count
        }
    }

    public var values: [T] {
        lock.sync {
            return Array(content)
        }
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
        lock.sync {
            return content.popLast()
        }
    }

    public func insert(_ item: T, at index: Int) {
        lock.sync {
            content.insert(item, at: index)
        }
    }

    public var isEmpty: Bool {
        lock.sync {
            return content.isEmpty
        }
    }

    /// Bracket get / set pattern
    public subscript(_ index: Int) -> T {
        get {
            lock.sync {
                return content[index]
            }
        }
        set {
            lock.sync {
                guard content[safe: index] != nil else {
                    content.insert(newValue, at: index)
                    return
                }
                content[index] = newValue
            }
        }
    }

    public func removeAll(keepCapacity: Bool = false) {
        lock.sync {
            return content.removeAll(keepingCapacity: keepCapacity)
        }
    }

    public func removeAll(where shouldBeRemoved: (T) throws -> Bool) rethrows {
        try lock.sync {
            return try content.removeAll(where: shouldBeRemoved)
        }
    }

    public var first: T? {
        lock.sync {
            return content.first
        }
    }

    /// Get an `enumerator` on a snapshot of the content
    public func enumerated() -> EnumeratedSequence<[T]> {
        lock.sync {
            return content.enumerated()
        }
    }

    /// Get an `Iterator` on a snapshot of the content
    public func makeIterator() -> IndexingIterator<[T]> {
        lock.sync {
            return content.makeIterator()
        }
    }
}
