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

@testable import Alamofire
@testable import InfomaniakCore
import InfomaniakDI
import XCTest

final class UTDecodeApiResponse: XCTestCase {
    override func setUp() {
        let factory = Factory(
            type: IKErrorRegistry.self
        ) { _, _ in
            return IKErrorRegistry(
                unknownHandledError: HandledError(code: .unknown, localizedMessage: "unknown", shouldDisplay: true),
                unknownApiHandledError: HandledError(code: .unknown, localizedMessage: "api", shouldDisplay: true),
                serverHandledError: HandledError(code: .unknown, localizedMessage: "server", shouldDisplay: true),
                networkHandledError: HandledError(code: .unknown, localizedMessage: "network", shouldDisplay: true),
                apiHandledErrors: [HandledError(
                    code: .apiError("testError"),
                    localizedMessage: "this is a test error",
                    shouldDisplay: true
                )]
            )
        }
        SimpleResolver.sharedResolver.store(factory: factory)
    }

    func fakeDataResponse<T: Decodable>(decodedResponse: ApiResponse<T>) -> DataResponse<ApiResponse<T>, AFError> {
        DataResponse(
            request: nil,
            response: HTTPURLResponse(),
            data: nil,
            metrics: nil,
            serializationDuration: 0,
            result: .success(decodedResponse)
        )
    }

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
        let dataResponse = fakeDataResponse(decodedResponse: decodedResponse!)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        XCTAssertNoThrow(
            try apiFetcher.handleApiResponse(dataResponse), "handleApiResponse shouldn't throw"
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
        let dataResponse = fakeDataResponse(decodedResponse: decodedResponse!)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        XCTAssertNoThrow(try apiFetcher.handleApiResponse(dataResponse), "handleApiResponse shouldn't throw")
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
        let dataResponse = fakeDataResponse(decodedResponse: decodedResponse!)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        do {
            _ = try apiFetcher.handleApiResponse(dataResponse)
        } catch {
            let ikError = error as? any IKError
            XCTAssertNotNil(ikError, "Error should be IKError")
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
        let dataResponse = fakeDataResponse(decodedResponse: decodedResponse!)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        do {
            _ = try apiFetcher.handleApiResponse(dataResponse)
        } catch {
            let ikError = error as? any IKError
            XCTAssertNotNil(ikError, "Error should be IKError")
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
        let dataResponse = fakeDataResponse(decodedResponse: decodedResponse!)

        // THEN
        XCTAssertNotNil(decodedResponse, "Response shouldn't be nil")
        do {
            _ = try apiFetcher.handleApiResponse(dataResponse)
        } catch {
            let ikError = error as? any IKError
            XCTAssertNotNil(ikError, "Error should be IKError")
            if let apiError = ikError as? ApiError {
                XCTAssertEqual(apiError.code, "testError", "Error code should be decoded")
            }
        }
    }
}
