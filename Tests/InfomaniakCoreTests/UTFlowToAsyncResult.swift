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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class UTFlowToAsyncResult: XCTestCase {
    // MARK: Standard usage

    func testSuccess() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"

        // WHEN
        // Events should start at least one run loop after the call to `result`
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            flowWrapper.send(someResult)
        }

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
        flowWrapper.send(completion: .failure(expectedError))

        // THEN
        let result = await flowWrapper.result
        guard case .failure(let error) = result, let domainError = error as? SomeError else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(domainError, expectedError)
    }

    // MARK: Potential miss-use

    func testDoubleSendSuccess() async {
        // GIVEN
        let flowWrapper = FlowToAsyncResult<String>()
        let someResult = "Some random computational result 💽"
        let someOtherResult = "Some competitor 💿"

        // WHEN
        // Events should start at least one run loop after the call to `result`
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            flowWrapper.send(someResult)
            flowWrapper.send(someOtherResult)
        }

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
        // Events should start at least one run loop after the call to `result`
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            flowWrapper.send(someResult)
            flowWrapper.send(someOtherResult)
            flowWrapper.send(completion: .failure(expectedError))
        }
        

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
        flowWrapper.send(completion: .failure(expectedError))
        flowWrapper.send(completion: .failure(otherError))

        // THEN
        let result = await flowWrapper.result
        guard case .failure(let error) = result, let domainError = error as? SomeError else {
            XCTFail("Unexpected result :\(result)")
            return
        }
        XCTAssertEqual(domainError, expectedError)
    }
}
