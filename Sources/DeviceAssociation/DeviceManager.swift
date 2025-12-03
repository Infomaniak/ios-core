/*
 Infomaniak Core - iOS
 Copyright (C) 2025 Infomaniak Network SA

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
import InfomaniakCore
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
    let appMarketingVersion: String
    let capabilities: [Capability]

    enum ErrorDomain: Error {
        case containerURLUnavailable
        case writeError
    }

    public init(appGroupIdentifier: String, appMarketingVersion: String, capabilities: [Capability]) {
        self.appGroupIdentifier = appGroupIdentifier
        self.appMarketingVersion = appMarketingVersion
        self.capabilities = Array(Set(capabilities))
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
            return await UserDevice(uid: deviceIdString, appMarketingVersion: appMarketingVersion, capabilities: capabilities)
        } else {
            let userDeviceUUID = UUID().uuidString
            guard let deviceIdData = userDeviceUUID.data(using: .utf8) else {
                throw ErrorDomain.writeError
            }

            try deviceIdData.write(to: deviceIdFileURL)

            return await UserDevice(uid: userDeviceUUID, appMarketingVersion: appMarketingVersion, capabilities: capabilities)
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
        guard let previousDeviceHash = getDeviceHash(forUserId: token.userId) else {
            return true
        }

        let currentDeviceHash = device.stableHashValue
        return currentDeviceHash != previousDeviceHash
    }

    func removeDeviceHash(forUserId userId: Int) {
        let key = "deviceHash_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
    }

    func setDeviceHash(_ device: UserDevice, forUserId userId: Int) {
        let key = "deviceHash_\(userId)"
        UserDefaults.standard.set(device.stableHashValue, forKey: key)
    }

    func getDeviceHash(forUserId userId: Int) -> String? {
        let key = "deviceHash_\(userId)"
        let hash = UserDefaults.standard.string(forKey: key)
        return hash
    }
}
