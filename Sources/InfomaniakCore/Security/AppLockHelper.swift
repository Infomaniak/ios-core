/*
 Infomaniak Core - iOS
 Copyright (C) 2021 Infomaniak Network SA

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

import LocalAuthentication

struct AppLockHelper {
    static var shared = AppLockHelper()

    private var lastAppLock: Double = 0
    private let appUnlockTime: Double = 10 * 60 // 10 minutes

    private init() {}

    var isAppLocked: Bool {
        return lastAppLock + appUnlockTime < Date().timeIntervalSince1970
    }

    mutating func setTime() {
        lastAppLock = Date().timeIntervalSince1970
    }

    func evaluatePolicy(reason: String) async throws -> Bool {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { return false }
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
}
