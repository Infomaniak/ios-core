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

final class UTItemProviderTextRepresentation: XCTestCase {
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

    // MARK: ItemProviderTextRepresentation

    func testText_String() async {
        // GIVEN
        let someText: NSString = "Some Text" // for NSCoding
        let item = NSItemProvider(item: someText, typeIdentifier: "\(UTI.text.rawValue)")

        do {
            let provider = try ItemProviderTextRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertGreaterThanOrEqual(success.lastPathComponent.count, 17 + ".txt".count, "non empty title")
            XCTAssertLessThanOrEqual(success.lastPathComponent.count, 30 + ".txt".count, "smaller than UUID")
            XCTAssertTrue(success.lastPathComponent.hasSuffix("txt"))

            let stringResult = try String(contentsOf: success, encoding: .utf8) as NSString // for NSCoding
            XCTAssertEqual(stringResult, someText)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testText_Data() async {
        // GIVEN
        let someTextData = "Some Text".data(using: .utf8)! as NSData // For NSCoding
        let item = NSItemProvider(item: someTextData, typeIdentifier: "\(UTI.text.rawValue)")

        do {
            let provider = try ItemProviderTextRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")

            XCTAssertGreaterThanOrEqual(success.lastPathComponent.count, 17 + ".txt".count, "non empty title")
            XCTAssertLessThanOrEqual(success.lastPathComponent.count, 30 + ".txt".count, "smaller than UUID")
            XCTAssertTrue(success.lastPathComponent.hasSuffix("txt"))

            let stringResult = try String(contentsOf: success, encoding: .utf8) as NSString // for NSCoding
            XCTAssertEqual(stringResult, "Some Text")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}

#endif
