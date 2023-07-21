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
final class UTItemProviderWeblocRepresentation: XCTestCase {
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

    // MARK: ItemProviderWeblocRepresentation

    func testWebloc() async {
        // GIVEN
        let someURL = URL(string: "file://some/path/image.jpg")!
        let item = NSItemProvider(contentsOf: someURL)!

        // WHEN
        do {
            let provider = try ItemProviderWeblocRepresentation(from: item)

            // THEN
            let success = try await provider.result.get()
            XCTAssertEqual(success.lastPathComponent, "image.jpg.webloc")

        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}

#endif
