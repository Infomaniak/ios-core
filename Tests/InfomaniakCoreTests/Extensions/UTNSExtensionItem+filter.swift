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
import XCTest

final class UTNSExtensionItemFilter: XCTestCase {
    static let pdfFile = "dummy"

    func testFilterItemProviders_justOnePDF() {
        // GIVEN
        let extensionItem = NSExtensionItem()

        guard let pdfFile = Bundle.module.url(forResource: Self.pdfFile, withExtension: "pdf") else {
            XCTFail("unexpected")
            return
        }

        guard let pdfItemProvider = NSItemProvider(contentsOf: pdfFile) else {
            XCTFail("unexpected")
            return
        }

        extensionItem.attachments = [pdfItemProvider]
        let extensionItems = [extensionItem]

        // WHEN
        let itemProviders = extensionItems.filteredItemProviders

        // THEN
        XCTAssertEqual(itemProviders.count, 1, "We expect to get exactly our item provider")
        XCTAssertEqual(itemProviders.first, pdfItemProvider, "We expect to get back the PDF item provider")
    }

    func testFilterItemProviders_justOneURL() {
        // GIVEN
        let extensionItem = NSExtensionItem()

        let someURL = URL(string: "about:blank")!
        let urlItemProvider = NSItemProvider(contentsOf: someURL)!

        extensionItem.attachments = [urlItemProvider]
        let extensionItems = [extensionItem]

        // WHEN
        let itemProviders = extensionItems.filteredItemProviders

        // THEN
        XCTAssertEqual(itemProviders.count, 1, "We expect to get exactly our item provider")
        XCTAssertEqual(itemProviders.first, urlItemProvider, "We expect to get back the URL item provider")
    }

    /// Mimmic what Safari would generate when sharing from a webpage displaying a PDF
    func testFilterItemProviders_URLAndPDF_ThereCanBeOnlyOne() {
        // GIVEN
        let extensionItem = NSExtensionItem()

        let someURL = URL(string: "about:blank")!
        let urlItemProvider = NSItemProvider(contentsOf: someURL)!

        guard let pdfFile = Bundle.module.url(forResource: Self.pdfFile, withExtension: "pdf") else {
            XCTFail("unexpected")
            return
        }

        guard let pdfItemProvider = NSItemProvider(contentsOf: pdfFile) else {
            XCTFail("unexpected")
            return
        }

        extensionItem.attachments = [urlItemProvider, pdfItemProvider]
        let extensionItems = [extensionItem]

        // WHEN
        let itemProviders = extensionItems.filteredItemProviders

        // THEN
        XCTAssertEqual(itemProviders.count, 1, "We expect to get exactly our item provider")
        XCTAssertEqual(itemProviders.first, pdfItemProvider, "We expect to get back the PDF item provider")
    }

    func testFilterItemProviders_multipleAbstractFiles_noChange() {
        // GIVEN
        let extensionItem = NSExtensionItem()

        let someURL = URL(string: "about:blank")!
        let urlItemProvider = NSItemProvider(contentsOf: someURL)!

        guard let pdfFile = Bundle.module.url(forResource: Self.pdfFile, withExtension: "pdf") else {
            XCTFail("unexpected")
            return
        }

        guard let pdfItemProvider = NSItemProvider(contentsOf: pdfFile) else {
            XCTFail("unexpected")
            return
        }

        let attachments = [urlItemProvider, pdfItemProvider, urlItemProvider, pdfItemProvider, urlItemProvider]
        let expectedItemCount = attachments.count

        extensionItem.attachments = attachments
        let extensionItems = [extensionItem]

        // WHEN
        let itemProviders = extensionItems.filteredItemProviders

        // THEN
        XCTAssertEqual(itemProviders.count, expectedItemCount, "We expect to get all our item providers")
    }

    func testFilterItemProviders_multiplePDF_noChange() {
        // GIVEN
        let extensionItem = NSExtensionItem()

        guard let pdfFile = Bundle.module.url(forResource: Self.pdfFile, withExtension: "pdf") else {
            XCTFail("unexpected")
            return
        }

        guard let pdfItemProvider = NSItemProvider(contentsOf: pdfFile) else {
            XCTFail("unexpected")
            return
        }

        let attachments = [pdfItemProvider, pdfItemProvider, pdfItemProvider, pdfItemProvider, pdfItemProvider]
        let expectedItemCount = attachments.count

        extensionItem.attachments = attachments
        let extensionItems = [extensionItem]

        // WHEN
        let itemProviders = extensionItems.filteredItemProviders

        // THEN
        XCTAssertEqual(itemProviders.count, expectedItemCount, "We expect to get all our PDF item providers")
    }

    func testFilterItemProviders_multipleURL_noChange() {
        // GIVEN
        let extensionItem = NSExtensionItem()

        let someURL = URL(string: "about:blank")!
        let urlItemProvider = NSItemProvider(contentsOf: someURL)!

        let attachments = [urlItemProvider, urlItemProvider, urlItemProvider, urlItemProvider, urlItemProvider]
        let expectedItemCount = attachments.count

        extensionItem.attachments = attachments
        let extensionItems = [extensionItem]

        // WHEN
        let itemProviders = extensionItems.filteredItemProviders

        // THEN
        XCTAssertEqual(itemProviders.count, expectedItemCount, "We expect to get all our URL item providers")
    }
}

#endif
