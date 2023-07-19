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

import InfomaniakCore
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class UTFlowToAsyncResult: XCTestCase {
    // MARK: Standard usage

    func testSuccess() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"

        // WHEN
        flowWrapper.sendSuccess(someResult)

        // THEN
        let result = await flowWrapper.result
        guard case .success(let success) = result else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(success, someResult)
    }

    func testFailure() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let expectedError = SomeError.some

        enum SomeError: Error, Equatable {
            case some
        }

        // WHEN
        flowWrapper.sendFailure(expectedError)

        // THEN
        let result = await flowWrapper.result
        guard case .failure(let error) = result, let domainError = error as? SomeError else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(domainError, expectedError)
    }

    // MARK: Multiple calls

    func testDoubleSuccess() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"

        // WHEN
        flowWrapper.sendSuccess(someResult)
        flowWrapper.sendSuccess(someResult)

        // THEN
        let result = await flowWrapper.result
        guard case .success(let success) = result else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(success, someResult)
    }

    func testDoubleSuccessDiff() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"
        let someOtherResult = "Some competitor 💿"

        // WHEN
        flowWrapper.sendSuccess(someResult)
        flowWrapper.sendSuccess(someOtherResult)

        // THEN
        let result = await flowWrapper.result
        guard case .success(let success) = result else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(success, someResult)
    }

    func testDoubleSendSuccessAndFailure() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"
        let someOtherResult = "Some competitor 💿"

        enum SomeError: Error, Equatable {
            case some
        }

        let expectedError = SomeError.some

        // WHEN
        flowWrapper.sendSuccess(someResult)
        flowWrapper.sendSuccess(someOtherResult)
        flowWrapper.sendFailure(expectedError)

        // THEN
        let result = await flowWrapper.result
        guard case .success(let success) = result else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(success, someResult)
    }

    func testFailureDoubleSend() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let expectedError = SomeError.some
        let otherError = SomeError.other

        enum SomeError: Error, Equatable {
            case some
            case other
        }

        // WHEN
        flowWrapper.sendFailure(expectedError)
        flowWrapper.sendFailure(otherError)

        // THEN
        let result = await flowWrapper.result
        guard case .failure(let error) = result, let domainError = error as? SomeError else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(domainError, expectedError)
    }

    // MARK: Multiple calls _and_ async calls

    func testSuccess_late() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"

        // WHEN
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            flowWrapper.sendSuccess(someResult)
        }

        // THEN
        let result = await flowWrapper.result
        guard case .success(let success) = result else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(success, someResult)
    }

    func testDoubleSendSuccess_late() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"
        let someOtherResult = "Some competitor 💿"

        // WHEN
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            flowWrapper.sendSuccess(someResult)
            flowWrapper.sendSuccess(someOtherResult)
        }

        // THEN
        let result = await flowWrapper.result
        guard case .success(let success) = result else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(success, someResult)
    }

    func testDoubleSendSuccessAndFailure_late() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"
        let someOtherResult = "Some competitor 💿"

        enum SomeError: Error, Equatable {
            case some
        }

        let expectedError = SomeError.some

        // WHEN
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            flowWrapper.sendSuccess(someResult)
            flowWrapper.sendSuccess(someOtherResult)
            flowWrapper.sendFailure(expectedError)
        }

        // THEN
        let result = await flowWrapper.result
        guard case .success(let success) = result else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(success, someResult)
    }

    func testFailureDoubleSend_late() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let expectedError = SomeError.some
        let otherError = SomeError.other

        enum SomeError: Error, Equatable {
            case some
            case other
        }

        // WHEN
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            flowWrapper.sendFailure(expectedError)
            flowWrapper.sendFailure(otherError)
        }

        // THEN
        let result = await flowWrapper.result
        guard case .failure(let error) = result, let domainError = error as? SomeError else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(domainError, expectedError)
    }
}
