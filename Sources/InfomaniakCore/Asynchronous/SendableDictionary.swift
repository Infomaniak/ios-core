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
/// Useful when dealing with UI.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class SendableDictionary<T: Hashable, U>: @unchecked Sendable {
    let lock = DispatchQueue(label: "com.infomaniak.core.SendableDictionary.lock")
    private(set) var content = [T: U]()

    public init() {
        // META: keep SonarCloud happy
    }

    public var values: Dictionary<T, U>.Values {
        var buffer: Dictionary<T, U>.Values!
        lock.sync {
            buffer = content.values
        }
        return buffer
    }

    public func value(for key: T) -> U? {
        var buffer: U?
        lock.sync {
            buffer = content[key]
        }
        return buffer
    }

    public func setValue(_ value: U?, for key: T) {
        lock.sync {
            content[key] = value
        }
    }

    @discardableResult
    public func removeValue(forKey key: T) -> U? {
        var buffer: U?
        lock.sync {
            buffer = content.removeValue(forKey: key)
        }
        return buffer
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
