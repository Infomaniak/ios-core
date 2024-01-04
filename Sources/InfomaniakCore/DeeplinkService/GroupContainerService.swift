//
//  File.swift
//
//
//  Created by Ambroise Decouttere on 28/12/2023.
//

import Foundation

@available(iOS 14, *)
struct GroupContainerService {
    static func writeToGroupContainer(group: String, file: URL) throws -> URL? {
        guard let sharedContainerURL: URL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: group) else { return nil }

        let groupContainer = sharedContainerURL.appendingPathComponent("Library/Caches/file-sharing", conformingTo: .directory)
        let destination = groupContainer.appendingPathComponent(file.lastPathComponent)

        if FileManager.default.fileExists(atPath: groupContainer.path) {
            try FileManager.default.removeItem(at: groupContainer)
        }
        try FileManager.default.createDirectory(at: groupContainer, withIntermediateDirectories: false)
        try FileManager.default.copyItem(
            at: file,
            to: destination
        )
        return destination
    }
}
