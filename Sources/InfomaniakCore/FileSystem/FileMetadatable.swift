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

/// Access metadata of a file
public protocol FileMetadatable {
    /// Read file modification date form metadata
    func fileModificationDate(url: URL) -> Date?

    /// Read file creation date form metadata
    func fileCreationDate(url: URL) -> Date?

    /// Read file size form metadata
    func fileSize(url: URL) -> UInt64?
}

public struct FileMetadata: FileMetadatable {
    public init() {
        // FileMetadata service init
    }

    public func fileModificationDate(url: URL) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[FileAttributeKey.modificationDate] as? Date
        } catch {
            SentryDebug.fileMetadataBreadcrumb(["error": error])
            return nil
        }
    }

    public func fileCreationDate(url: URL) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[FileAttributeKey.creationDate] as? Date
        } catch {
            SentryDebug.fileMetadataBreadcrumb(["error": error])
            return nil
        }
    }

    public func fileSize(url: URL) -> UInt64? {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return fileAttributes[FileAttributeKey.size] as? UInt64
        } catch {
            SentryDebug.fileMetadataBreadcrumb(["error": error])
            return nil
        }
    }
}
