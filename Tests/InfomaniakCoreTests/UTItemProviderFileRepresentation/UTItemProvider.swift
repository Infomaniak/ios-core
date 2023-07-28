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
final class UTItemProvider: XCTestCase {
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

    /// Image from wikimedia under CC.
    static let imageFile = "Matterhorn_as_seen_from_Zermatt,_Wallis,_Switzerland,_2012_August,Wikimedia_Commons"
    
    // MARK: hasItemConformingToAnyOfTypeIdentifiers

    func testHasItemConformingToAnyOfTypeIdentifiers_image_conformImage() {
        // GIVEN
        guard let imgUrlJpg = Bundle.module.url(forResource: Self.imageFile, withExtension: "jpg") else {
            XCTFail("unexpected")
            return
        }

        guard let jpgImageItem = NSItemProvider(contentsOf: imgUrlJpg) else {
            XCTFail("unexpected")
            return
        }

        // WHEN
        let hasConformance = jpgImageItem.hasItemConformingToAnyOfTypeIdentifiers([UTI.image.identifier])

        // THEN
        XCTAssertTrue(hasConformance)
    }

    func testHasItemConformingToAnyOfTypeIdentifiers_image_conformText() {
        // GIVEN
        guard let imgUrlJpg = Bundle.module.url(forResource: Self.imageFile, withExtension: "jpg") else {
            XCTFail("unexpected")
            return
        }

        guard let jpgImageItem = NSItemProvider(contentsOf: imgUrlJpg) else {
            XCTFail("unexpected")
            return
        }

        // WHEN
        let hasConformance = jpgImageItem.hasItemConformingToAnyOfTypeIdentifiers([UTI.text.identifier])

        // THEN
        XCTAssertFalse(hasConformance)
    }

    func testHasItemConformingToAnyOfTypeIdentifiers_text_conformsText() {
        // GIVEN
        let someText: NSString = "Some Text" // for NSCoding
        let textItem = NSItemProvider(item: someText, typeIdentifier: "\(UTI.text.rawValue)")

        // WHEN
        let hasConformance = textItem.hasItemConformingToAnyOfTypeIdentifiers([UTI.text.identifier])

        // THEN
        XCTAssertTrue(hasConformance)
    }

    func testHasItemConformingToAnyOfTypeIdentifiers_text_conformsImage() {
        // GIVEN
        let someText: NSString = "Some Text" // for NSCoding
        let textItem = NSItemProvider(item: someText, typeIdentifier: "\(UTI.text.rawValue)")

        // WHEN
        let hasConformance = textItem.hasItemConformingToAnyOfTypeIdentifiers([UTI.image.identifier])

        // THEN
        XCTAssertFalse(hasConformance)
    }
}

#endif
