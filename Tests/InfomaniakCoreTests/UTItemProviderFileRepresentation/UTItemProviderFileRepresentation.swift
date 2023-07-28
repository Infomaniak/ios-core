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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class UTItemProviderFileRepresentation: XCTestCase {
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

    /// Image from wikimedia under CC.
    static let imageFile = "Matterhorn_as_seen_from_Zermatt,_Wallis,_Switzerland,_2012_August,Wikimedia_Commons"

    // MARK: - Text file

    func testFile() async {
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

            let fileRepresentation = try ItemProviderFileRepresentation(from: fileItem)
            let progress = fileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await fileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.pathExtension.lowercased(), "txt")

            let stringResult = try String(contentsOf: success, encoding: .utf8) as NSString // for NSCoding
            XCTAssertEqual(stringResult, someText)

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    // MARK: - Image file

    // MARK: Retrieve Image without conversion

    func testJPGImageNoChange() async {
        // GIVEN
        guard let imgUrlJpg = Bundle.module.url(forResource: Self.imageFile, withExtension: "jpg") else {
            XCTFail("unexpected")
            return
        }

        guard let jpgImageItem = NSItemProvider(contentsOf: imgUrlJpg) else {
            XCTFail("unexpected")
            return
        }

        do {
            let fileRepresentation = try ItemProviderFileRepresentation(from: jpgImageItem)
            let progress = fileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await fileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.pathExtension.lowercased(), "jpeg")

            let imageData = try Data(contentsOf: success)
            XCTAssertTrue(imageData.count > 0, "expecting to find a non empty file")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testHEICImageNoChange() async {
        // GIVEN
        guard let imgUrlHeic = Bundle.module.url(forResource: Self.imageFile, withExtension: "heic") else {
            XCTFail("unexpected")
            return
        }

        guard let heicImageItem = NSItemProvider(contentsOf: imgUrlHeic) else {
            XCTFail("unexpected")
            return
        }

        do {
            let fileRepresentation = try ItemProviderFileRepresentation(from: heicImageItem)
            let progress = fileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await fileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.pathExtension.lowercased(), "heic")

            let imageData = try Data(contentsOf: success)
            XCTAssertTrue(imageData.count > 0, "expecting to find a non empty file")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    // MARK: Retrieve Image _with_ conversion

    func testHEICtoJPEG_success() async {
        // GIVEN
        guard let imgUrlHeic = Bundle.module.url(forResource: Self.imageFile, withExtension: "heic"),
              let imgUrlJpg = Bundle.module.url(forResource: Self.imageFile, withExtension: "jpg") else {
            XCTFail("unexpected")
            return
        }

        // Prepare an NSItemProvider with both JPG and HEIC counterparts
        let imageDataHeic = NSData(contentsOf: imgUrlHeic)
        let heicImageItem = NSItemProvider(item: imageDataHeic, typeIdentifier: UTI.heic.identifier)
        heicImageItem.registerItem(forTypeIdentifier: UTI.jpeg.identifier) { completionHandler, expectedValueClass, options in
            let imageDataJpg = NSData(contentsOf: imgUrlJpg)
            completionHandler?(imageDataJpg, nil)
        }

        do {
            let fileRepresentation = try ItemProviderFileRepresentation(from: heicImageItem, preferredImageFileFormat: UTI.jpeg)
            let progress = fileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await fileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.pathExtension.lowercased(), "jpeg")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testJPEGtoHEIC_success() async {
        // GIVEN
        guard let imgUrlHeic = Bundle.module.url(forResource: Self.imageFile, withExtension: "heic"),
              let imgUrlJpg = Bundle.module.url(forResource: Self.imageFile, withExtension: "jpg") else {
            XCTFail("unexpected")
            return
        }

        // Prepare an NSItemProvider with both JPG and HEIC counterparts
        let imageDataJpg = NSData(contentsOf: imgUrlJpg)
        let heicImageItem = NSItemProvider(item: imageDataJpg, typeIdentifier: UTI.jpeg.identifier)
        heicImageItem.registerItem(forTypeIdentifier: UTI.heic.identifier) { completionHandler, expectedValueClass, options in
            let imageDataHeic = NSData(contentsOf: imgUrlHeic)
            completionHandler?(imageDataHeic, nil)
        }

        do {
            let fileRepresentation = try ItemProviderFileRepresentation(from: heicImageItem, preferredImageFileFormat: UTI.jpeg)
            let progress = fileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await fileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.pathExtension.lowercased(), "jpeg")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    // MARK: Retrieve Image _with_ conversion failure and _fallback_

    func testHEICtoJPG_fallbackToHEIC() async {
        // GIVEN
        guard let imgUrlHeic = Bundle.module.url(forResource: Self.imageFile, withExtension: "heic") else {
            XCTFail("unexpected")
            return
        }

        guard let heicImageItem = NSItemProvider(contentsOf: imgUrlHeic) else {
            XCTFail("unexpected")
            return
        }

        do {
            let heicFileRepresentation = try ItemProviderFileRepresentation(
                from: heicImageItem,
                preferredImageFileFormat: UTI.jpeg
            )
            let progress = heicFileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await heicFileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")

            // We expect a HEIC fallback when no JPG is available
            XCTAssertEqual(success.pathExtension.lowercased(), "heic")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testJPGtoHEIC_fallbackToJPEG() async {
        // GIVEN
        guard let imgUrlJpg = Bundle.module.url(forResource: Self.imageFile, withExtension: "jpg") else {
            XCTFail("unexpected")
            return
        }

        guard let jpgImageItem = NSItemProvider(contentsOf: imgUrlJpg) else {
            XCTFail("unexpected")
            return
        }

        do {
            let heicFileRepresentation = try ItemProviderFileRepresentation(
                from: jpgImageItem,
                preferredImageFileFormat: UTI.heic
            )
            let progress = heicFileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await heicFileRepresentation.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")

            // We expect a JPEG fallback when no HEIC is available
            XCTAssertEqual(success.pathExtension.lowercased(), "jpeg")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    // MARK: Retrieve Image _with_ conversion, source is not an image

    func testJPGfromText_fallback() async {
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

            let fileRepresentation = try ItemProviderFileRepresentation(from: fileItem, preferredImageFileFormat: UTI.heic)
            let progress = fileRepresentation.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN absurdly asking a HEIC from a TXT file
            let success = try await fileRepresentation.result.get()

            // THEN we still get an unchanged TXT file
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.pathExtension.lowercased(), "txt")

            let stringResult = try String(contentsOf: success, encoding: .utf8) as NSString // for NSCoding
            XCTAssertEqual(stringResult, someText)

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}

#endif
