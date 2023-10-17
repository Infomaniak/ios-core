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

public extension [NSExtensionItem] {
    /// A type identifier that represents an URL
    private static let urlTypeIdentifier = "public.url"

    /// A view on  underlying `NSItemProvider` suitable for kDrive and Mail shareExtensions
    ///
    /// Filters out extraneous webpage URLs when we care only about a concrete file
    /// Eg. We remove the URL of the website when exporting an arbitrary file, like a PDF
    var filteredItemProviders: [NSItemProvider] {
        let itemProviders = compactMap(\.attachments).flatMap { $0 }

        // We only apply a filter when we have exactly two items
        guard itemProviders.count == 2 else {
            return itemProviders
        }

        // We remove the first matching item
        guard let indexToRemove = itemProviders.firstIndex(where: { itemProvider in
            // We only check the first "main" type identifier, a PDF can also have an url pointing to the file.
            itemProvider.registeredTypeIdentifiers.first == Self.urlTypeIdentifier
        }) else {
            return itemProviders
        }

        var buffer = itemProviders
        buffer.remove(at: indexToRemove)
        return buffer
    }
}
