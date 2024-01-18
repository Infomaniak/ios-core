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
import SwiftUI

@available(iOS 13.0, *)
public extension Collection where Element: Identifiable {
    /// Compute a stable id for the given collection
    func collectionId(baseId: AnyHashable? = nil) -> Int {
        var hasher = Hasher()
        hasher.combine(baseId)
        forEach { hasher.combine($0.id) }
        return hasher.finalize()
    }
}
