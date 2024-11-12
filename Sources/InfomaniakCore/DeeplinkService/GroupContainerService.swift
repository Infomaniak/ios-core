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
    static func writeToGroupContainer(group: String, file: URL) throws -> URL? {
        guard let sharedContainerURL: URL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: group) else { return nil }

        let groupContainer = sharedContainerURL.appendingPathComponent(
            "Library/Caches/file-sharing/\(UUID().uuidString)/",
            isDirectory: true
        )
        let destination = groupContainer.appendingPathComponent(file.lastPathComponent)

        if FileManager.default.fileExists(atPath: groupContainer.path) {
            try FileManager.default.removeItem(at: groupContainer)
        }
        try FileManager.default.createDirectory(at: groupContainer, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: file,
            to: destination
        )
        return destination
    }
}
