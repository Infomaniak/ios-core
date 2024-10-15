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
import RealmSwift

/// This property wrapper ensures that the passed object (or collection) is frozen. In case the given object isn't frozen an
/// assert is raised.
@propertyWrapper
public struct EnsureFrozen<Value> {
    public let wrappedValue: Value

    public init(wrappedValue: Value) {
        #if DEBUG
        if let threadConfined = wrappedValue as? ThreadConfined {
            assert(threadConfined.isFrozen, "Object should be frozen")
        } else if let collection = wrappedValue as? (any Collection) {
            assert(
                collection.compactMap { $0 as? ThreadConfined }.allSatisfy { $0.isFrozen },
                "All objects in collection should be frozen"
            )
        }
        #endif
        self.wrappedValue = wrappedValue
    }
}
