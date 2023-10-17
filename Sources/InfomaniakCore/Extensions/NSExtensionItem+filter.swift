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
    static let urlTypeIdentifier = "public.url"
    
    /// A view on  underlying `NSItemProvider` suitable for kDrive and Mail shareExtensions
    ///
    /// If multiple results, all `NSItemProvider.type` that equals `public.url` are striped down.
    /// Eg. We remove the URL of the website when exporting an arbitrary file, like a PDF
    var filteredItemProviders: [NSItemProvider] {
        var itemProviders = compactMap(\.attachments).flatMap { $0 }
        guard itemProviders.count > 1 else {
            return itemProviders
        }

        itemProviders.removeAll { itemProvider in
            itemProvider.registeredTypeIdentifiers.contains(Self.urlTypeIdentifier)
        }

        return itemProviders
    }
}
