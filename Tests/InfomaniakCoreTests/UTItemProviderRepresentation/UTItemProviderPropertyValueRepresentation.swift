/*
 Infomaniak Core - iOS
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCore
@testable import InfomaniakDI
import XCTest

final class UTItemProviderPropertyValueRepresentation: XCTestCase {
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

    // MARK: -

    func testProvideDictionary() async {
        // GIVEN
        let someDictionary: NSDictionary = ["key": "value"]
        let item = NSItemProvider(item: someDictionary, typeIdentifier: UTI.propertyList.identifier)

        let provider = ItemProviderPropertyValueRepresentation(from: item)
        XCTAssertFalse(provider.progress.isFinished)

        do {
            // WHEN
            let result = try await provider.result.get()

            // THEN
            XCTAssertEqual(result, someDictionary)
            XCTAssertTrue(provider.progress.isFinished)
        } catch {
            XCTFail("Unexpected error:\(error)")
        }
    }

    func testUnableToProvideDictionary() async {
        // GIVEN
        let garbageInput = "la li lu le lo" as NSSecureCoding
        let item = NSItemProvider(item: garbageInput, typeIdentifier: UTI.propertyList.identifier)

        let provider = ItemProviderPropertyValueRepresentation(from: item)
        XCTAssertFalse(provider.progress.isFinished)

        do {
            // WHEN
            let result = try await provider.result.get()

            // THEN
            XCTFail("Should throw. got \(result)")
        } catch {
            guard let error = error as? ItemProviderPropertyValueRepresentation.ErrorDomain else {
                XCTFail("Unexpected error :\(error)")
                return
            }

            guard error == .unableToReadDictionary else {
                XCTFail("Unexpected domain error :\(error)")
                return
            }

            XCTAssertTrue(provider.progress.isFinished)
        }
    }
}
