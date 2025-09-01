/*
 Infomaniak kDrive - iOS App
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

/// Extending NSItemProvider for detecting file type, business logic.
public extension NSItemProvider {
    /// image file identifiers supported by the app
    private static let imageUTIIdentifiers = [
        UTI.jpeg.identifier,
        UTI.tiff.identifier,
        UTI.gif.identifier,
        UTI.png.identifier,
        UTI.icns.identifier,
        UTI.bmp.identifier,
        UTI.ico.identifier,
        UTI.rawImage.identifier,
        UTI.svg.identifier,
        UTI.livePhoto.identifier,
        UTI.heic.identifier
    ]

    /// archive identifiers supported by the app
    private static let compressedUTIIdentifiers = [
        UTI.zip.identifier,
        UTI.bz2.identifier,
        UTI.gzip.identifier,
        UTI.archive.identifier
    ]

    /// directory identifiers supported by the app
    private static let directoryUTIIdentifiers = [
        UTI.directory.identifier,
        UTI.folder.identifier,
        UTI.filesAppFolder.identifier
    ]

    /// Subset of types supported by the Apps
    enum ItemUnderlyingType: Equatable {
        /// The item is an URL
        case isURL
        /// The item is Text
        case isText
        /// The item is an UIImage
        case isUIImage
        /// The item is image Data (heic or jpg)
        case isImageData
        /// The item is a Directory
        case isDirectory
        /// The item is a compressed file
        case isCompressedData(identifier: String)
        /// The item is a property list
        case isPropertyList
        /// The item is of a miscellaneous type
        case isMiscellaneous(identifier: String)
        /// This should not happen, no type identifier was found
        case none
    }

    /// Wrapping business logic of supported types by the apps.
    var underlyingType: ItemUnderlyingType {
        // We expect to have a type identifier to work with
        guard let typeIdentifier = registeredTypeIdentifiers.first else {
            return .none
        }

        if hasItemConformingToTypeIdentifier(UTI.url.identifier) && registeredTypeIdentifiers.count == 1 {
            return .isURL
        } else if hasItemConformingToTypeIdentifier(UTI.plainText.identifier)
            && !hasItemConformingToTypeIdentifier(UTI.fileURL.identifier)
            && canLoadObject(ofClass: String.self) {
            return .isText
        } else if hasItemConformingToAnyOfTypeIdentifiers(Self.imageUTIIdentifiers) {
            return .isImageData
        } else if registeredTypeIdentifiers.count == 1 &&
            registeredTypeIdentifiers.first == UTI.image.identifier {
            return .isUIImage
        } else if hasItemConformingToAnyOfTypeIdentifiers(Self.directoryUTIIdentifiers) {
            return .isDirectory
        } else if hasItemConformingToAnyOfTypeIdentifiers(Self.compressedUTIIdentifiers) {
            return .isCompressedData(identifier: typeIdentifier)
        } else if hasItemConformingToTypeIdentifier(UTI.propertyList.identifier) {
            return .isPropertyList
        } else {
            return .isMiscellaneous(identifier: typeIdentifier)
        }
    }

    /// Check if item is conforming to *at least* one identifier provided
    /// - Parameter collection: A collection of identifiers
    /// - Returns: `true` if matches for at least one identifier
    func hasItemConformingToAnyOfTypeIdentifiers(_ collection: [String]) -> Bool {
        let hasItem = collection.contains { identifier in
            self.hasItemConformingToTypeIdentifier(identifier)
        }

        return hasItem
    }
}
