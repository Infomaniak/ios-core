/*
 Copyright 2025 Infomaniak Network SA

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import InfomaniakLogin

public protocol DeviceManagerable: Sendable {
    func getOrCreateCurrentDevice() async throws -> UserDevice

    @discardableResult
    func attachDeviceIfNeeded(_ device: UserDevice, to token: ApiToken,
                              apiFetcher: ApiFetcher) async throws -> ValidServerResponse<Bool>?

    func forgetLocalDeviceHash(forUserId userId: Int)
}

public struct DeviceManager: DeviceManagerable {
    let appGroupIdentifier: String

    enum ErrorDomain: Error {
        case containerURLUnavailable
        case writeError
    }

    public init(appGroupIdentifier: String) {
        self.appGroupIdentifier = appGroupIdentifier
    }

    public func getOrCreateCurrentDevice() async throws -> UserDevice {
        let appGroupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        guard var deviceManagerURL = appGroupContainerURL?.appendingPathComponent("DeviceManager", isDirectory: true)
        else {
            throw ErrorDomain.containerURLUnavailable
        }

        if !FileManager.default.fileExists(atPath: deviceManagerURL.path) {
            try FileManager.default.createDirectory(at: deviceManagerURL, withIntermediateDirectories: true, attributes: nil)
            // We exclude device manager from backup because keeping a device Id from two different devices doesn't make sense
            var metadata = URLResourceValues()
            metadata.isExcludedFromBackup = true
            try deviceManagerURL.setResourceValues(metadata)
        }

        let deviceIdFileURL = deviceManagerURL.appendingPathComponent("/deviceId")
        if FileManager.default.fileExists(atPath: deviceIdFileURL.path),
           let deviceIdData = try? Data(contentsOf: deviceIdFileURL),
           let deviceIdString = String(data: deviceIdData, encoding: .utf8) {
            return await UserDevice(uid: deviceIdString)
        } else {
            let userDeviceUUID = UUID().uuidString
            guard let deviceIdData = userDeviceUUID.data(using: .utf8) else {
                throw ErrorDomain.writeError
            }

            try deviceIdData.write(to: deviceIdFileURL)

            return await UserDevice(uid: userDeviceUUID)
        }
    }

    @discardableResult
    public func attachDeviceIfNeeded(_ device: UserDevice,
                                     to token: ApiToken,
                                     apiFetcher: ApiFetcher) async throws -> ValidServerResponse<Bool>? {
        guard shouldAttachDevice(device, to: token) else {
            return nil
        }

        let apiResponse = try await apiFetcher.attachDevice(toAPIToken: token, deviceMetaData: device)
        setDeviceHash(device, forUserId: token.userId)

        return apiResponse
    }

    public func forgetLocalDeviceHash(forUserId userId: Int) {
        removeDeviceHash(forUserId: userId)
    }
}

extension DeviceManager {
    func shouldAttachDevice(_ device: UserDevice, to token: ApiToken) -> Bool {
        let deviceHash = device.hashValue
        guard let previousDeviceHash = getDeviceHash(forUserId: token.userId) else {
            return true
        }

        return previousDeviceHash != deviceHash
    }

    func removeDeviceHash(forUserId userId: Int) {
        let key = "deviceHash_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
    }

    func setDeviceHash(_ device: UserDevice, forUserId userId: Int) {
        let key = "deviceHash_\(userId)"
        UserDefaults.standard.set(device.hashValue, forKey: key)
    }

    func getDeviceHash(forUserId userId: Int) -> Int? {
        let key = "deviceHash_\(userId)"
        return UserDefaults.standard.integer(forKey: key)
    }
}
