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

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension Array {
    /// Returns an `ArraySlice` for the specified indexes if possible.
    /// The Slice is bounded to the size of the current collection.
    subscript(safe range: Range<Index>) -> ArraySlice<Element> {
        return self[Swift.min(range.startIndex, endIndex) ..< Swift.min(range.endIndex, endIndex)]
    }
}
