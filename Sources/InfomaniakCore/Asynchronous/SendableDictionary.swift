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

/// A thread safe Dictionary wrapper that does not require `await`. Conforms to Sendable.
///
/// Please prefer using first party structured concurrency. Use this for prototyping or dealing with race conditions.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class SendableDictionary<T: Hashable, U>: @unchecked Sendable {
    let lock = DispatchQueue(label: "com.infomaniak.core.SendableDictionary.lock")
    private(set) var content = [T: U]()

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

    public var values: Dictionary<T, U>.Values {
        lock.sync {
            return content.values
        }
    }

    public func value(for key: T) -> U? {
        lock.sync {
            return content[key]
        }
    }

    public func setValue(_ value: U?, for key: T) {
        lock.sync {
            content[key] = value
        }
    }

    @discardableResult
    public func removeValue(forKey key: T) -> U? {
        lock.sync {
            return content.removeValue(forKey: key)
        }
    }

    /// Bracket get / set pattern
    public subscript(_ key: T) -> U? {
        get {
            value(for: key)
        }
        set {
            setValue(newValue, for: key)
        }
    }
}
