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

import Foundation
import OSLog

public enum BackgroundExecutor {
    private static let logger = Logger(category: "BackgroundExecutor")

    public typealias TaskCompletion = () -> Void
    public static func executeWithBackgroundTask(_ block: @escaping (@escaping TaskCompletion) -> Void,
                                                 onExpired: @escaping () -> Void) {
        let taskName = "executeWithBackgroundTask \(UUID().uuidString)"
        let processInfos = ProcessInfo()
        let group = TolerantDispatchGroup()
        group.enter()
        #if os(macOS)
        logger.debug("Starting task \(taskName) (No expiration handler as we are running on macOS)")
        processInfos.performActivity(options: .suddenTerminationDisabled, reason: taskName) {
            block {
                logger.debug("Ending task \(taskName)")
                group.leave()
            }
            group.wait()
        }
        #else
        logger.debug("Starting task \(taskName)")
        processInfos.performExpiringActivity(withReason: taskName) { expired in
            if expired {
                onExpired()
                logger.debug("Expired task \(taskName)")
                group.leave()
            } else {
                block {
                    logger.debug("Ending task \(taskName)")
                    group.leave()
                }
                group.wait()
            }
        }
        #endif
    }
}
