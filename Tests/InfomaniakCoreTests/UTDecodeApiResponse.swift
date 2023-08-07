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

@testable import InfomaniakCore
import XCTest

@available(iOS 13.0, *)
final class UTDecodeApiResponse: XCTestCase {
    func testDecodeNullDataResponse() throws {
        // GIVEN
        let apiFetcher = ApiFetcher()
        let jsonData = """
        {
        "result": "success",
        "data": null
        }
        """.data(using: .utf8)!

        // WHEN
        let decodedResponse = try? JSONDecoder().decode(ApiResponse<NullableResponse>.self, from: jsonData)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        XCTAssertNoThrow(
            try apiFetcher.handleApiResponse(decodedResponse!, responseStatusCode: 0),
            "handleApiResponse shouldn't throw"
        )
    }

    func testDecodeDataResponse() throws {
        // GIVEN
        let apiFetcher = ApiFetcher()
        let jsonData = """
        {
        "result": "success",
        "data": 1
        }
        """.data(using: .utf8)!

        // WHEN
        let decodedResponse = try? JSONDecoder().decode(ApiResponse<Int>.self, from: jsonData)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        XCTAssertNoThrow(
            try apiFetcher.handleApiResponse(decodedResponse!, responseStatusCode: 0),
            "handleApiResponse shouldn't throw"
        )
    }

    func testDecodeErrorNullApiResponse() throws {
        // GIVEN
        let apiFetcher = ApiFetcher()
        let jsonData = """
        {
        "result": "error"
        }
        """.data(using: .utf8)!

        // WHEN
        let decodedResponse = try? JSONDecoder().decode(ApiResponse<Int>.self, from: jsonData)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        do {
            let _ = try apiFetcher.handleApiResponse(decodedResponse!, responseStatusCode: 0)
        } catch {
            let ikError = error as? InfomaniakError
            XCTAssertNotNil(ikError, "Error should be InfomaniakError")
        }
    }

    func testDecodeErrorDataApiResponse() throws {
        // GIVEN
        let apiFetcher = ApiFetcher()
        let jsonData = """
        {
        "result": "error",
        "data": 1
        }
        """.data(using: .utf8)!

        // WHEN
        let decodedResponse = try? JSONDecoder().decode(ApiResponse<Int>.self, from: jsonData)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        do {
            let _ = try apiFetcher.handleApiResponse(decodedResponse!, responseStatusCode: 0)
        } catch {
            let ikError = error as? InfomaniakError
            XCTAssertNotNil(ikError, "Error should be InfomaniakError")
        }
    }

    func testDecodeErrorApiResponse() throws {
        // GIVEN
        let apiFetcher = ApiFetcher()
        let jsonData = """
        {
        "result": "error",
        "error": {
        "code": "testError",
        "description": "this is a test error"
        }
        }
        """.data(using: .utf8)!

        // WHEN
        let decodedResponse = try? JSONDecoder().decode(ApiResponse<Int>.self, from: jsonData)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        do {
            let _ = try apiFetcher.handleApiResponse(decodedResponse!, responseStatusCode: 0)
        } catch {
            let ikError = error as? InfomaniakError
            XCTAssertNotNil(ikError, "Error should be InfomaniakError")
            if case .apiError(let apiError) = ikError {
                XCTAssertEqual(apiError.code, "testError", "Error code should be decoded")
            }
        }
    }
}
