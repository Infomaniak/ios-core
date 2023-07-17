/*
 Infomaniak kDrive - iOS App
 Copyright (C) 2021 Infomaniak Network SA

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

#if canImport(MobileCoreServices)

import Foundation

/// Extending URL with UTI helpers
public extension URL {
    /// Try to provide a typeIdentifier `String` for the current URL
    var typeIdentifier: String? {
        if hasDirectoryPath {
            return UTI.folder.identifier
        }
        if FileManager.default.fileExists(atPath: path) {
            return try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
        } else {
            // If the file is not downloaded, we get the type identifier using its extension
            return UTI(filenameExtension: pathExtension, conformingTo: .item)?.identifier
        }
    }

    /// Try to provide an `UTI` for the current URL
    var uti: UTI? {
        if let typeIdentifier = typeIdentifier {
            return UTI(typeIdentifier)
        }
        return nil
    }

    /// Try to provide the creationDate `Date` for the current URL
    var creationDate: Date? {
        return try? resourceValues(forKeys: [.creationDateKey]).creationDate
    }

    /// Try to append the correct file type extension for a given UTI
    func appendingPathExtension(for contentType: UTI) -> URL {
        guard let newExtension = contentType.preferredFilenameExtension,
              pathExtension != newExtension else {
            return self
        }

        return appendingPathExtension(newExtension)
    }

    /// Try to append the correct file type extension to current `URL`
    mutating func appendPathExtension(for contentType: UTI) {
        self = appendingPathExtension(for: contentType)
    }
}

#endif