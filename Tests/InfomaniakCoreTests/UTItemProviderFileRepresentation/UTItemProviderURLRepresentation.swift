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
final class UTItemProviderURLRepresentation: XCTestCase {
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

    // MARK: ItemProviderURLRepresentation

    func testLocalFile_success() async {
        // GIVEN
        guard let imgUrlJpg = Bundle.module.url(forResource: Self.imageFile, withExtension: "jpg") else {
            XCTFail("unexpected")
            return
        }

        guard let item = NSItemProvider(contentsOf: imgUrlJpg) else {
            XCTFail("unexpected")
            return
        }

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.lastPathComponent, Self.imageFile + ".jpg")

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testWebloc_success() async {
        // GIVEN
        let someURL = URL(string: "file://some/path/index.html")!
        let item = NSItemProvider(contentsOf: someURL)!

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.lastPathComponent, "index.webloc")

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testWebloc_emptyName() async {
        // GIVEN
        let someURL = URL(string: "about:blank")!
        let item = NSItemProvider(contentsOf: someURL)!

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertGreaterThanOrEqual(success.lastPathComponent.count, 17 + ".webloc".count, "non empty title")
            XCTAssertLessThanOrEqual(success.lastPathComponent.count, 30 + ".webloc".count, "smaller than UUID")

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}

#endif