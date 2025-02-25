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
import Network

public class ReachabilityListener {
    public enum NetworkStatus {
        case undefined
        case offline
        case wifi
        case cellular
    }

    private var eventQueue = DispatchQueue(
        label: "\(Bundle.main.bundleIdentifier ?? "com.infomaniak.core").network-listener",
        autoreleaseFrequency: .workItem
    )

    private var observersQueue = DispatchQueue(
        label: "\(Bundle.main.bundleIdentifier ?? "com.infomaniak.core").network-listener.observers",
        attributes: .concurrent
    )

    private var networkMonitor: NWPathMonitor
    private var didChangeNetworkStatus = [UUID: (NetworkStatus) -> Void]()
    public private(set) var currentStatus: NetworkStatus
    public static let instance = ReachabilityListener()

    private init() {
        networkMonitor = NWPathMonitor()
        currentStatus = .undefined
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else {
                return
            }

            let newStatus = self.pathToStatus(path)
            guard newStatus != self.currentStatus else {
                return
            }

            self.currentStatus = newStatus
            self.observersQueue.sync {
                for closure in self.didChangeNetworkStatus.values {
                    closure(self.currentStatus)
                }
            }
        }
        networkMonitor.start(queue: eventQueue)
    }

    private func pathToStatus(_ path: NWPath) -> NetworkStatus {
        if path.status == .satisfied {
            if path.usesInterfaceType(.cellular) {
                return .cellular
            } else {
                return .wifi
            }
        } else {
            return .offline
        }
    }
}

// MARK: - Observation

public extension ReachabilityListener {
    @discardableResult
    func observeNetworkChange<T: AnyObject>(_ observer: T, using closure: @escaping (NetworkStatus) -> Void)
        -> ObservationToken {
        let key = UUID()
        observersQueue.async(flags: .barrier) { [weak self] in
            self?.didChangeNetworkStatus[key] = { [weak observer] status in
                // If the observer has been deallocated, we can
                // automatically remove the observation closure.
                guard observer != nil else {
                    self?.didChangeNetworkStatus.removeValue(forKey: key)
                    return
                }

                closure(status)
            }
        }

        return ObservationToken { [weak self] in
            self?.observersQueue.async(flags: .barrier) {
                self?.didChangeNetworkStatus.removeValue(forKey: key)
            }
        }
    }
}
