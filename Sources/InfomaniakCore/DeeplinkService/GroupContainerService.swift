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

enum GroupContainerService {
    enum Error: Swift.Error, Equatable {
        case invalidFileCount
        case invalidFileName
        case unavailableGroupContainer
        case unsupportedFile
        case unsafeHandoffDirectory
    }

    static func writeToGroupContainer(group: String, file: URL) throws -> URL {
        let fileManager = FileManager.default
        guard let sharedContainerURL = fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: group) else {
            throw Error.unavailableGroupContainer
        }

        return try writeToGroupContainer(
            sharedContainerURL: sharedContainerURL,
            file: file,
            fileManager: fileManager
        )
    }

    static func writeToGroupContainer(
        sharedContainerURL: URL,
        file: URL,
        fileManager: FileManager = .default,
        makeIdentifier: () -> String = { UUID().uuidString }
    ) throws -> URL {
        let sourceURL = file.standardizedFileURL
        guard sourceURL.isFileURL,
              let safeFileName = sourceURL.lastPathComponent.safeLastPathComponent else {
            throw Error.invalidFileName
        }

        let sourceValues = try sourceURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard sourceValues.isRegularFile == true, sourceValues.isSymbolicLink != true else {
            throw Error.unsupportedFile
        }

        let handoffDirectoryURL = KDriveFileSharing.handoffDirectoryURL(in: sharedContainerURL)
        let groupContainerURL = handoffDirectoryURL.appendingPathComponent(makeIdentifier(), isDirectory: true)
        let destinationURL = groupContainerURL.appendingPathComponent(safeFileName, isDirectory: false)

        var createdContainer = false
        do {
            try fileManager.createDirectory(at: handoffDirectoryURL, withIntermediateDirectories: true)
            let handoffValues = try handoffDirectoryURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard handoffValues.isDirectory == true, handoffValues.isSymbolicLink != true else {
                throw Error.unsafeHandoffDirectory
            }
            try fileManager.createDirectory(at: groupContainerURL, withIntermediateDirectories: false)
            createdContainer = true
            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            let destinationValues = try destinationURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard destinationValues.isRegularFile == true, destinationValues.isSymbolicLink != true else {
                throw Error.unsupportedFile
            }
            return destinationURL
        } catch {
            if createdContainer {
                try? fileManager.removeItem(at: groupContainerURL)
            }
            throw error
        }
    }
}
