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
            XCTAssertEqual(success.url.lastPathComponent, Self.imageFile + ".jpg")
            XCTAssertTrue(success.url.lastPathComponent.hasSuffix(".jpg"))
            XCTAssertEqual(success.title, UTItemProviderURLRepresentation.imageFile)

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
            XCTAssertGreaterThanOrEqual(success.url.lastPathComponent.count, 17 + ".webloc".count, "non empty title")
            XCTAssertLessThanOrEqual(success.url.lastPathComponent.count, 30 + ".webloc".count, "smaller than UUID")
            XCTAssertTrue(success.url.lastPathComponent.hasSuffix(".webloc"))
            XCTAssertGreaterThanOrEqual(success.title.count, 10, "title should be non empty")

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    @available(iOS 16.0, *)
    func testWebloc_successWebMainPage() async {
        // GIVEN
        let someURL = URL(string: "https://infomaniak.com/")!
        let item = NSItemProvider(contentsOf: someURL)!
        let expectedTitle = "infomaniak_com"
        let expectedFileName = "\(expectedTitle).webloc"

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()
            let title = success.url.lastPathComponent

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertTrue(title.hasSuffix(".webloc"), "Expecting a .webloc extension, got:\(title)")
            XCTAssertEqual(title, expectedFileName)
            XCTAssertEqual(success.title, expectedTitle)

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    @available(iOS 16.0, *)
    func testWebloc_successWebMainPageWWW() async {
        // GIVEN
        let someURL = URL(string: "https://www.infomaniak.com/")!
        let item = NSItemProvider(contentsOf: someURL)!
        let expectedTitle = "infomaniak_com"
        let expectedFileName = "\(expectedTitle).webloc"

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()
            let title = success.url.lastPathComponent

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertTrue(title.hasSuffix(".webloc"), "Expecting a .webloc extension, got:\(title)")
            XCTAssertEqual(title, expectedFileName)
            XCTAssertEqual(success.title, expectedTitle)

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    @available(iOS 16.0, *)
    func testWebloc_successWebMainPageAlt() async {
        // GIVEN
        let someURL = URL(string: "https://infomaniak.com")!
        let item = NSItemProvider(contentsOf: someURL)!
        let expectedTitle = "infomaniak_com"
        let expectedFileName = "\(expectedTitle).webloc"

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()
            let title = success.url.lastPathComponent

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertTrue(title.hasSuffix(".webloc"), "Expecting a .webloc extension, got:\(title)")
            XCTAssertEqual(title, expectedFileName)
            XCTAssertEqual(success.title, expectedTitle)

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testWebloc_successWebIndexPage() async {
        // GIVEN
        let expectedTitle = "index"
        let someURL = URL(string: "https://infomaniak.com/\(expectedTitle).html")!
        let item = NSItemProvider(contentsOf: someURL)!

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let success = try await provider.result.get()

            // THEN
            XCTAssertTrue(progress.isFinished, "Expecting the progress to reflect that the task is finished")
            XCTAssertEqual(success.url.lastPathComponent, "index.webloc")
            XCTAssertEqual(success.title, expectedTitle)

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testWebloc_nonExistingLocalFile() async {
        // GIVEN
        let someURL = URL(string: "file://dev/null/somefile.txt")!
        let item = NSItemProvider(contentsOf: someURL)!

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let _ = try await provider.result.get()

            // THEN
            XCTFail("Expecting to throw")

        } catch {
            guard let error = error as? ItemProviderURLRepresentation.ErrorDomain else {
                XCTFail("Unexpected \(error)")
                return
            }
            XCTAssertEqual(
                error,
                ItemProviderURLRepresentation.ErrorDomain.localFileNotFound,
                "Expecting to not be able to find a local file"
            )
        }
    }

    func testWebloc_malformedLocalFile() async {
        // GIVEN
        let someURL = URL(string: "file://infomaniak.com/index.html")!
        let item = NSItemProvider(contentsOf: someURL)!

        do {
            let provider = try ItemProviderURLRepresentation(from: item)
            let progress = provider.progress
            XCTAssertFalse(progress.isFinished, "Expecting the progress to reflect that the task has not started yet")

            // WHEN
            let _ = try await provider.result.get()

            // THEN
            XCTFail("Expecting to throw")

        } catch {
            guard let error = error as? ItemProviderURLRepresentation.ErrorDomain else {
                XCTFail("Unexpected \(error)")
                return
            }
            XCTAssertEqual(
                error,
                ItemProviderURLRepresentation.ErrorDomain.localFileNotFound,
                "Expecting to not be able to find a local file"
            )
        }
    }
}

#endif
