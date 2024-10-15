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

import CocoaLumberjackSwift
import Foundation

public final class TolerantDispatchGroup {
    let syncQueue: DispatchQueue
    private let dispatchGroup = DispatchGroup()
    private var callBalancer = 0

    /// Init method of TolerantDispatchGroup
    /// - Parameter qos: The QoS of the underlying queue. Default to `.userInitiated` to prevent most priority inversions
    public init(qos: DispatchQoS = .userInitiated) {
        syncQueue = DispatchQueue(label: "com.infomaniak.TolerantDispatchGroup", qos: qos)
    }

    public func enter() {
        syncQueue.sync {
            dispatchGroup.enter()
            callBalancer += 1
        }
    }

    public func leave() {
        syncQueue.sync {
            guard callBalancer > 0 else {
                DDLogWarn("TolerantDispatchGroup: Unbalanced call to leave()")
                return
            }

            dispatchGroup.leave()
            callBalancer -= 1
        }
    }

    public func wait() {
        dispatchGroup.wait()
    }
}
