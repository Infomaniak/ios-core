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

@testable import InfomaniakCore
import XCTest

final class MCKExpiringActivityDelegate: ExpiringActivityDelegate {
    var backgroundActivityExpiringCallCount = 0
    var backgroundActivityExpiringCalled: Bool {
        backgroundActivityExpiringCallCount > 0
    }

    func backgroundActivityExpiring() {
        backgroundActivityExpiringCallCount += 1
    }
}

final class ITExpiringActivity: XCTestCase {
    /// Random time between 1 sec and 150ms, expressed in nanoseconds
    var randomNanosecondsWait: UInt64 {
        return UInt64.random(in: 150_000_000 ... 1_000_000_000)
    }

    // MARK: - Open / Close activity

    func testSimpleUseCase() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)

        // WHEN
        activity.start()
        activity.endAll()

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, 0)
    }

    func testSimpleAsyncUseCase() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)

        // WHEN
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        activity.start()
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        activity.endAll()
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, 0)
    }

    func testUnbalancedStart() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)

        // WHEN
        _ = (1 ... 5).map { _ in activity.start() }
        activity.endAll()

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, 0)
    }

    func testAsyncUnbalancedStart() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)

        // WHEN
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        activity.start()
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        _ = (1 ... 3).map { _ in activity.start() }
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        _ = (1 ... 2).map { _ in activity.start() }
        activity.endAll()
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, 0)
    }

    func testUnbalancedStartMultipleEnd() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)

        // WHEN
        _ = (1 ... 4).map { _ in activity.start() }
        activity.endAll()
        _ = (1 ... 4).map { _ in activity.start() }
        activity.endAll()
        _ = (1 ... 4).map { _ in activity.start() }
        activity.endAll()

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, 0)
    }

    func testAsyncUnbalancedStartMultipleEnd() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)

        // WHEN
        _ = (1 ... 4).map { _ in activity.start() }
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        activity.endAll()
        _ = (1 ... 4).map { _ in activity.start() }
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        activity.endAll()
        _ = (1 ... 4).map { _ in activity.start() }
        try! await Task.sleep(nanoseconds: randomNanosecondsWait)
        activity.endAll()

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, 0)
    }

    // MARK: - Open only

    func testStart() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)

        // WHEN
        activity.start()

        // respect call conventions, after checking assertions
        defer {
            activity.endAll()
            XCTAssertEqual(activity.locks.count, 0)
        }

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, 1)
    }

    func testMultipleStart() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)
        let expectedStartCalls = 4

        // WHEN
        _ = (1 ... expectedStartCalls).map { _ in activity.start() }

        // respect call conventions, after checking assertions
        defer {
            activity.endAll()
            XCTAssertEqual(activity.locks.count, 0)
        }

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, expectedStartCalls)
    }

    func testAsyncMultipleStart() async {
        // GIVEN
        let uid = UUID().uuidString
        let delegate = MCKExpiringActivityDelegate()
        let activity = ExpiringActivity(id: uid, delegate: delegate)
        let expectedStartCalls = 4

        // WHEN
        let starts = Task {
            activity.start()
            try! await Task.sleep(nanoseconds: randomNanosecondsWait)
            activity.start()
            try! await Task.sleep(nanoseconds: randomNanosecondsWait)
            activity.start()
            activity.start()
        }
        await starts.finish()

        // respect call conventions, after checking assertions
        defer {
            activity.endAll()
            XCTAssertEqual(activity.locks.count, 0)
        }

        // THEN
        XCTAssertEqual(delegate.backgroundActivityExpiringCallCount, 0)
        XCTAssertEqual(activity.locks.count, expectedStartCalls)
    }
}
