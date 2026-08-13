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
import XCTest

final class UTGroupContainerService: XCTestCase {
    private let fileManager = FileManager.default
    private var testRootURL: URL!
    private var sharedContainerURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        testRootURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        sharedContainerURL = testRootURL.appendingPathComponent("shared", isDirectory: true)
        try fileManager.createDirectory(at: sharedContainerURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: testRootURL)
        try super.tearDownWithError()
    }

    func testWritesRegularFileToExpectedHandoffDirectory() throws {
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
        XCTAssertEqual(destinationURL.deletingLastPathComponent(), expectedDirectoryURL)
        XCTAssertEqual(destinationURL.lastPathComponent, sourceURL.lastPathComponent)
        XCTAssertEqual(try Data(contentsOf: destinationURL), content)
    }

    func testRejectsInvalidFileCount() {
        XCTAssertThrowsError(try DeeplinkService().shareFilesToKdrive([])) { error in
            XCTAssertEqual(error as? GroupContainerService.Error, .invalidFileCount)
        }

        let files = Array(repeating: URL(fileURLWithPath: "/tmp/file"), count: KDriveFileSharing.maximumFileCount + 1)
        XCTAssertThrowsError(try DeeplinkService().shareFilesToKdrive(files)) { error in
            XCTAssertEqual(error as? GroupContainerService.Error, .invalidFileCount)
        }
    }

    func testRejectsDirectoryAndSymlink() throws {
        let directoryURL = testRootURL.appendingPathComponent("directory", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false)

        let sourceURL = testRootURL.appendingPathComponent("source.txt")
        try Data().write(to: sourceURL)
        let symlinkURL = testRootURL.appendingPathComponent("link.txt")
        try fileManager.createSymbolicLink(at: symlinkURL, withDestinationURL: sourceURL)

        for unsupportedURL in [directoryURL, symlinkURL] {
            XCTAssertThrowsError(
                try GroupContainerService.writeToGroupContainer(
                    sharedContainerURL: sharedContainerURL,
                    file: unsupportedURL
                )
            ) { error in
                XCTAssertEqual(error as? GroupContainerService.Error, .unsupportedFile)
            }
        }
    }

    func testRejectsUnsafeFileName() throws {
        let sourceURL = testRootURL.appendingPathComponent("unsafe%name.txt")
        try Data().write(to: sourceURL)

        XCTAssertThrowsError(
            try GroupContainerService.writeToGroupContainer(
                sharedContainerURL: sharedContainerURL,
                file: sourceURL
            )
        ) { error in
            XCTAssertEqual(error as? GroupContainerService.Error, .invalidFileName)
        }
    }

    func testRejectsSymlinkedHandoffDirectory() throws {
        let actualHandoffURL = testRootURL.appendingPathComponent("actual-handoff", isDirectory: true)
        try fileManager.createDirectory(at: actualHandoffURL, withIntermediateDirectories: true)

        let handoffURL = KDriveFileSharing.handoffDirectoryURL(in: sharedContainerURL)
        try fileManager.createDirectory(at: handoffURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: handoffURL, withDestinationURL: actualHandoffURL)

        let sourceURL = testRootURL.appendingPathComponent("file.txt")
        try Data().write(to: sourceURL)

        XCTAssertThrowsError(
            try GroupContainerService.writeToGroupContainer(
                sharedContainerURL: sharedContainerURL,
                file: sourceURL
            )
        ) { error in
            XCTAssertEqual(error as? GroupContainerService.Error, .unsafeHandoffDirectory)
        }
    }
}
