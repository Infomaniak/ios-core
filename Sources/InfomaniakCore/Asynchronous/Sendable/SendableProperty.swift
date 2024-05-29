/*
 Infomaniak Core - iOS
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

/// Making a property thread safe, while not requiring `await`. Conforms to Sendable.
///
/// Please prefer using first party structured concurrency. Use this for prototyping or dealing with race conditions.
@propertyWrapper
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class SendableProperty<Property>: @unchecked Sendable {
    /// Serial locking queue
    let lock = DispatchQueue(label: "com.infomaniak.core.SendableProperty.lock")

    /// Store property
    var property: Property?

    public init() {
        // META: Sonar Cloud happy
    }

    public var wrappedValue: Property? {
        get {
            lock.sync {
                return self.property
            }
        }
        set {
            lock.sync {
                self.property = newValue
            }
        }
    }

    /// The property wrapper itself for debugging and testing
    public var projectedValue: SendableProperty {
        self
    }
}
