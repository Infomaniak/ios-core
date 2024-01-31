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

import CocoaLumberjackSwift
import Foundation

/// Something to wrap arbitrary code that should be performed on the background.
public enum BackgroundExecutor {
    public typealias TaskCompletion = () -> Void

    /// Perform a short task in the background, be notified when the system wants to expire the task.
    /// - Parameters:
    ///   - qos: Optionally set a the QoS used by underlying GCD queues
    ///   - block: The work to be performed on the background
    ///   - onExpired: The closure called by the system when we should end.
    public static func executeWithBackgroundTask(qos: DispatchQoS = .userInitiated,
                                                 _ block: @escaping (@escaping TaskCompletion) -> Void,
                                                 onExpired: @escaping () -> Void) {
        let taskName = "executeWithBackgroundTask \(UUID().uuidString)"
        let processInfos = ProcessInfo()
        let group = TolerantDispatchGroup(qos: qos)
        group.enter()
        #if os(macOS)
        DDLogDebug("Starting task \(taskName) (No expiration handler as we are running on macOS)")
        processInfos.performActivity(options: .suddenTerminationDisabled, reason: taskName) {
            block {
                DDLogDebug("Ending task \(taskName)")
                group.leave()
            }
            group.wait()
        }
        #else
        DDLogDebug("Starting task \(taskName)")
        processInfos.performExpiringActivity(withReason: taskName) { expired in
            if expired {
                onExpired()
                DDLogDebug("Expired task \(taskName)")
                group.leave()
            } else {
                block {
                    DDLogDebug("Ending task \(taskName)")
                    group.leave()
                }
                group.wait()
            }
        }
        #endif
    }
}
