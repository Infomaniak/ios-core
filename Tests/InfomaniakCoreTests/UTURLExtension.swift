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

final class UTURLExtension: XCTestCase {

    // MARK: - typeIdentifier
    
    func testTypeIdentifier() {
        // GIVEN
        let someURL = URL(string: "file://some/path/image.jpg")!
        
        // WHEN
        let typeIdentifier = someURL.typeIdentifier
        
        // THEN
        XCTAssertEqual(typeIdentifier, "public.jpeg")
    }
    
    // MARK: - uti
    
    func testUTI() {
        // GIVEN
        let someURL = URL(string: "file://some/path/image.jpg")!
        
        // WHEN
        let uti = someURL.uti
        
        // THEN
        XCTAssertEqual(uti?.rawValue, "public.jpeg" as CFString)
    }
    
    // MARK: - creationDate
    
    func testCreationDate_nil() {
        // GIVEN
        let someURL = URL(string: "file://some/path/image.jpg")!
        
        // WHEN
        let date = someURL.creationDate
        
        // THEN
        XCTAssertNil(date)
    }
    
    // MARK: - appendPathExtension
    
    func testAppendPathExtension() {
        // GIVEN
        var someURL = URL(string: "file://some/path/image")!
        let uti = UTI(rawValue: "public.jpeg" as CFString)
        
        // WHEN
        someURL.appendPathExtension(for: uti)
        
        // THEN
        XCTAssertEqual(someURL.absoluteString, "file://some/path/image.jpeg")
    }
    
    func testAppendPathExtensionHasExtension() {
        // GIVEN
        var someURL = URL(string: "file://some/path/image.JPG")!
        let uti = UTI(rawValue: "public.jpeg" as CFString)
        
        // WHEN
        someURL.appendPathExtension(for: uti)
        
        // THEN
        XCTAssertEqual(someURL.absoluteString, "file://some/path/image.jpeg")
    }
    
    // MARK: - appendingPathExtension
    
    func testAppendingPathExtension() {
        // GIVEN
        let someURL = URL(string: "file://some/path/image")!
        let uti = UTI(rawValue: "public.jpeg" as CFString)
        
        // WHEN
        let newURL = someURL.appendingPathExtension(for: uti)
        
        // THEN
        XCTAssertEqual(newURL.absoluteString, "file://some/path/image.jpeg")
    }
    
    func testAppendingPathExtensionHasExtension() {
        // GIVEN
        let someURL = URL(string: "file://some/path/image.JPG")!
        let uti = UTI(rawValue: "public.jpeg" as CFString)
        
        // WHEN
        let newURL = someURL.appendingPathExtension(for: uti)
        
        // THEN
        XCTAssertEqual(newURL.absoluteString, "file://some/path/image.jpeg")
    }
    
}
#endif
