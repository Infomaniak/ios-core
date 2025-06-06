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

#if canImport(MobileCoreServices)

import InfomaniakCore
@testable import InfomaniakDI
import XCTest
import ZIPFoundation

final class UTItemProviderZipRepresentation: XCTestCase {
    private let fileManager = FileManager.default

    override func setUp() {
        let factory = Factory(
            type: AppGroupPathProvidable.self
        ) { _, _ in
            return AppGroupPathProvider(realmRootPath: "realm", appGroupIdentifier: "com.ik.test")!
        }
        SimpleResolver.sharedResolver.store(factory: factory)
    }

    override func tearDown() {
        SimpleResolver.sharedResolver.removeAll()
    }

    func cleanFile(_ url: URL) {
        try? fileManager.removeItem(at: url)
    }

    // MARK: ItemProviderZipRepresentation

    func testZipFolder_isDirectory() async {
        // GIVEN
        let someText: NSString = "Some Text" // for NSCoding
        let item = NSItemProvider(item: someText, typeIdentifier: "\(UTI.text.rawValue)")

        do {
            // Create a file from a sample text string
            let provider = try ItemProviderTextRepresentation(from: item)

            // URL of a file somewhere we have access to
            let mockedFileURL = try await provider.result.get()

            let pathComponents = mockedFileURL.pathComponents
            let pathComponentsCount = pathComponents.count
            let fileName = mockedFileURL.lastPathComponent
            guard let folderName = mockedFileURL.pathComponents[safe: pathComponentsCount - 2] else {
                XCTFail("Unexpected, should be able to get a folder name")
                return
            }

            // Sanity check
            XCTAssertTrue(mockedFileURL.lastPathComponent.hasSuffix("txt"))
            let folderToZipURL = mockedFileURL.deletingLastPathComponent()

            guard let folderItem = NSItemProvider(contentsOf: folderToZipURL) else {
                XCTFail("Unexpected")
                return
            }

            let zipFileRepresentation = try ItemProviderZipRepresentation(from: folderItem)
            let progress = zipFileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN We get the path of the zipped file
            let success = try await zipFileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.title, folderName, "Expecting the generated zip file to match the compressed folder name")
            XCTAssertGreaterThanOrEqual(
                success.url.lastPathComponent.count,
                30 + ".zip".count,
                "it should reflect the folder used, a UUID here"
            )
            XCTAssertEqual(success.url.pathExtension, "zip")

            // We create a folder to unzip content
            let unzipFolder = success.url.deletingLastPathComponent()
                .appendingPathComponent("Unzip", isDirectory: true)
            try fileManager.createDirectory(at: unzipFolder, withIntermediateDirectories: true)

            // We build the URL of the unzipped folder
            let fileNameFromUrl = success.url.lastPathComponent
            let unzipFolderName = fileNameFromUrl.replacingOccurrences(of: ".zip", with: "")
            let unzipFolderPath = unzipFolder.appendingPathComponent(unzipFolderName, isDirectory: true)

            // We perform the unzip
            try fileManager.unzipItem(at: success.url, to: unzipFolder)

            // check the content of the unzipped folder
            let items = try fileManager.contentsOfDirectory(at: unzipFolderPath, includingPropertiesForKeys: nil)
            XCTAssertEqual(items.count, 1)
            guard let unzippedItem = items.first else {
                XCTFail("Unexpected empty folder")
                return
            }

            XCTAssertEqual(unzippedItem.lastPathComponent, fileName, "file name should not change once unzipped")

            guard let unzipFileURL = items.first else {
                XCTFail("Expecting to find exactly one file in unzipped folder")
                return
            }

            let stringResult = try String(contentsOf: unzipFileURL, encoding: .utf8) as NSString // for NSCoding
            XCTAssertEqual(stringResult, someText)

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testZipFolder_file() async {
        // GIVEN
        let someText: NSString = "Some Text" // for NSCoding
        let item = NSItemProvider(item: someText, typeIdentifier: "\(UTI.text.rawValue)")

        do {
            // Create a file from a sample text string
            let provider = try ItemProviderTextRepresentation(from: item)

            // URL of a file somewhere we have access to
            let mockedFileURL = try await provider.result.get()

            // Sanity check
            XCTAssertTrue(mockedFileURL.lastPathComponent.hasSuffix("txt"))

            guard let fileItem = NSItemProvider(contentsOf: mockedFileURL) else {
                XCTFail("Unexpected")
                return
            }

            // WHEN
            let _ = try ItemProviderZipRepresentation(from: fileItem)
            XCTFail("Expected to throw")

            // THEN
        } catch {
            guard case ItemProviderZipRepresentation.ErrorDomain.notADirectory = error else {
                XCTFail("Unexpected \(error)")
                return
            }

            // OK
        }
    }
}

#endif
