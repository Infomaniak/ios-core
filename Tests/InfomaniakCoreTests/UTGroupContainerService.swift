/*
 Infomaniak Core - iOS
 Copyright (C) 2026 Infomaniak Network SA

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
@testable import InfomaniakCore
import Testing

@Suite("GroupContainerService Tests")
struct UTGroupContainerService {
    private let fileManager = FileManager.default
    private let testRootURL: URL
    private let sharedContainerURL: URL

    init() throws {
        testRootURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        sharedContainerURL = testRootURL.appendingPathComponent("shared", isDirectory: true)
        try fileManager.createDirectory(at: sharedContainerURL, withIntermediateDirectories: true)
    }

    @Test("Regular files are copied to the expected handoff directory")
    func writesRegularFileToExpectedHandoffDirectory() throws {
        defer { try? fileManager.removeItem(at: testRootURL) }

        let sourceURL = testRootURL.appendingPathComponent("file.txt")
        let content = Data("content".utf8)
        try content.write(to: sourceURL)
        let identifier = UUID().uuidString

        let destinationURL = try GroupContainerService.writeToGroupContainer(
            sharedContainerURL: sharedContainerURL,
            file: sourceURL
        ) { identifier }

        let expectedDirectoryURL = KDriveFileSharing.handoffDirectoryURL(in: sharedContainerURL)
            .appendingPathComponent(identifier, isDirectory: true)
        #expect(destinationURL.deletingLastPathComponent() == expectedDirectoryURL)
        #expect(destinationURL.lastPathComponent == sourceURL.lastPathComponent)
        #expect(try Data(contentsOf: destinationURL) == content)
    }

    @Test("Empty and excessive file lists are rejected")
    func rejectsInvalidFileCount() {
        defer { try? fileManager.removeItem(at: testRootURL) }

        #expect(throws: GroupContainerService.Error.invalidFileCount) {
            try DeeplinkService().shareFilesToKdrive([])
        }

        let files = Array(repeating: URL(fileURLWithPath: "/tmp/file"), count: KDriveFileSharing.maximumFileCount + 1)
        #expect(throws: GroupContainerService.Error.invalidFileCount) {
            try DeeplinkService().shareFilesToKdrive(files)
        }
    }

    @Test("Directories and symbolic links are rejected")
    func rejectsDirectoryAndSymlink() throws {
        defer { try? fileManager.removeItem(at: testRootURL) }

        let directoryURL = testRootURL.appendingPathComponent("directory", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false)

        let sourceURL = testRootURL.appendingPathComponent("source.txt")
        try Data().write(to: sourceURL)
        let symlinkURL = testRootURL.appendingPathComponent("link.txt")
        try fileManager.createSymbolicLink(at: symlinkURL, withDestinationURL: sourceURL)

        for unsupportedURL in [directoryURL, symlinkURL] {
            #expect(throws: GroupContainerService.Error.unsupportedFile) {
                try GroupContainerService.writeToGroupContainer(
                    sharedContainerURL: sharedContainerURL,
                    file: unsupportedURL
                )
            }
        }
    }

    @Test("Unsafe file names are rejected")
    func rejectsUnsafeFileName() throws {
        defer { try? fileManager.removeItem(at: testRootURL) }

        let sourceURL = testRootURL.appendingPathComponent("unsafe%name.txt")
        try Data().write(to: sourceURL)

        #expect(throws: GroupContainerService.Error.invalidFileName) {
            try GroupContainerService.writeToGroupContainer(
                sharedContainerURL: sharedContainerURL,
                file: sourceURL
            )
        }
    }

    @Test("A symbolic link cannot replace the handoff directory")
    func rejectsSymlinkedHandoffDirectory() throws {
        defer { try? fileManager.removeItem(at: testRootURL) }

        let actualHandoffURL = testRootURL.appendingPathComponent("actual-handoff", isDirectory: true)
        try fileManager.createDirectory(at: actualHandoffURL, withIntermediateDirectories: true)

        let handoffURL = KDriveFileSharing.handoffDirectoryURL(in: sharedContainerURL)
        try fileManager.createDirectory(at: handoffURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: handoffURL, withDestinationURL: actualHandoffURL)

        let sourceURL = testRootURL.appendingPathComponent("file.txt")
        try Data().write(to: sourceURL)

        #expect(throws: GroupContainerService.Error.unsafeHandoffDirectory) {
            try GroupContainerService.writeToGroupContainer(
                sharedContainerURL: sharedContainerURL,
                file: sourceURL
            )
        }
    }
}
