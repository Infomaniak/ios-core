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

@testable import DeviceAssociation
import Foundation
import InfomaniakCore
import InfomaniakLogin
import Testing

@Suite("UTDeviceManager_keyValueStore")
struct UTDeviceManager_keyValueStore {
    @Test("Save Device with DeviceManager", arguments: [Int.random(in: 1 ... 100), Int.random(in: 1 ... 100)])
    func deviceManagerSaveDevice(userId: Int) async throws {
        // GIVEN
        let uuid = UUID().uuidString
        let device = await UserDevice(uid: uuid)
        let deviceManager = DeviceManager(appGroupIdentifier: "group.infomaniak.deviceassociation")
        let expectedDeviceHash = device.stableHashValue
        deviceManager.removeDeviceHash(forUserId: userId)

        // WHEN
        deviceManager.setDeviceHash(device, forUserId: userId)

        // THEN
        guard let fetchedDeviceHash = deviceManager.getDeviceHash(forUserId: userId) else {
            Issue.record("unable to fetch the device, it should exist")
            return
        }
        #expect(fetchedDeviceHash == expectedDeviceHash, "The device hash does not match")
    }

    @Test("Remove Device hash with DeviceManager", arguments: [Int.random(in: 1 ... 100), Int.random(in: 1 ... 100)])
    func deviceManagerRemoveDeviceHash(userId: Int) async throws {
        // GIVEN
        let uuid = UUID().uuidString
        let device = await UserDevice(uid: uuid)
        let deviceManager = DeviceManager(appGroupIdentifier: "group.infomaniak.deviceassociation")
        deviceManager.setDeviceHash(device, forUserId: userId)
        #expect(deviceManager.getDeviceHash(forUserId: userId) != nil, "The device hash should exist at this point")

        // WHEN
        deviceManager.removeDeviceHash(forUserId: userId)

        // THEN
        #expect(deviceManager.getDeviceHash(forUserId: userId) == nil)
    }
}

@Suite("UTDeviceManager_shouldAttachDevice")
struct UTDeviceManager_shouldAttachDevice {
    @Test("Device cache logic in DeviceManager, attach on no device stored",
          arguments: [Int.random(in: 1 ... 100), Int.random(in: 1 ... 100)])
    func deviceManagerShouldAttach(userId: Int) async throws {
        // GIVEN
        let uuid = UUID().uuidString
        let device = await UserDevice(uid: uuid)
        let deviceManager = DeviceManager(appGroupIdentifier: "group.infomaniak.deviceassociation")
        deviceManager.removeDeviceHash(forUserId: userId)
        #expect(deviceManager.getDeviceHash(forUserId: userId) == nil, "The device hash should not exist at this point")

        let apiToken = ApiToken(
            accessToken: "123",
            expiresIn: 456,
            refreshToken: "789",
            scope: "101112",
            tokenType: "131415",
            userId: userId,
            expirationDate: Date(timeIntervalSinceNow: 120)
        )

        // WHEN
        let shouldAttachDevice = deviceManager.shouldAttachDevice(device, to: apiToken)

        // THEN
        #expect(shouldAttachDevice == true, "The device should be attached to the userId")
    }

    @Test("Device cache logic in DeviceManager, attach on different device stored",
          arguments: [Int.random(in: 1 ... 100), Int.random(in: 1 ... 100)])
    func deviceManagerShouldAttachOther(userId: Int) async throws {
        // GIVEN
        let device = await UserDevice(uid: UUID().uuidString)
        let otherDevice = await UserDevice(uid: UUID().uuidString)
        let deviceManager = DeviceManager(appGroupIdentifier: "group.infomaniak.deviceassociation")
        deviceManager.setDeviceHash(device, forUserId: userId)
        #expect(deviceManager.getDeviceHash(forUserId: userId) != nil, "A device hash should exist at this point")

        let apiToken = ApiToken(
            accessToken: "123",
            expiresIn: 456,
            refreshToken: "789",
            scope: "101112",
            tokenType: "131415",
            userId: userId,
            expirationDate: Date(timeIntervalSinceNow: 120)
        )

        // WHEN
        let shouldAttachDevice = deviceManager.shouldAttachDevice(otherDevice, to: apiToken)

        // THEN
        #expect(shouldAttachDevice == true, "The device should be attached")
    }

    @Test("Device cache logic in DeviceManager, attach on userId missmatch",
          arguments: [Int.random(in: 1 ... 100), Int.random(in: 1 ... 100)])
    func deviceManagerShouldAttachOtherUserId(userId: Int) async throws {
        // GIVEN
        let device = await UserDevice(uid: UUID().uuidString)
        let deviceManager = DeviceManager(appGroupIdentifier: "group.infomaniak.deviceassociation")
        deviceManager.setDeviceHash(device, forUserId: userId)
        #expect(deviceManager.getDeviceHash(forUserId: userId) != nil, "A device hash should exist at this point")
        let otherUserId = userId + 1
        #expect(otherUserId != userId, "We expect to have two different userId")

        let apiToken = ApiToken(
            accessToken: "123",
            expiresIn: 456,
            refreshToken: "789",
            scope: "101112",
            tokenType: "131415",
            userId: otherUserId,
            expirationDate: Date(timeIntervalSinceNow: 120)
        )

        // WHEN
        let shouldAttachDevice = deviceManager.shouldAttachDevice(device, to: apiToken)

        // THEN
        #expect(shouldAttachDevice == true, "The device should be attached on a userId difference")
    }

    @Test("Device cache logic in DeviceManager, prevent double attach",
          arguments: [Int.random(in: 1 ... 100), Int.random(in: 1 ... 100)])
    func deviceManagerShouldNotAttach(userId: Int) async throws {
        // GIVEN
        let uuid = UUID().uuidString
        let device = await UserDevice(uid: uuid)
        let deviceManager = DeviceManager(appGroupIdentifier: "group.infomaniak.deviceassociation")
        deviceManager.setDeviceHash(device, forUserId: userId)
        #expect(deviceManager.getDeviceHash(forUserId: userId) != nil, "A device hash should exist at this point")

        let apiToken = ApiToken(
            accessToken: "123",
            expiresIn: 456,
            refreshToken: "789",
            scope: "101112",
            tokenType: "131415",
            userId: userId,
            expirationDate: Date(timeIntervalSinceNow: 120)
        )

        // WHEN
        let shouldAttachDevice = deviceManager.shouldAttachDevice(device, to: apiToken)

        // THEN
        #expect(shouldAttachDevice == false, "The same device should not be re-attached to the same userId")
    }
}

@Suite("UTDeviceManager_getOrCreateCurrentDevice")
struct UTDeviceManager_getOrCreateCurrentDevice {
    @Test("get a userDevice from the public interface and check stability",
          arguments: [Int.random(in: 1 ... 100), Int.random(in: 1 ... 100)])
    func currentDevice(userId: Int) async throws {
        // GIVEN
        let deviceManager = DeviceManager(appGroupIdentifier: "group.infomaniak.deviceassociation")

        // WHEN
        do {
            let currentDevice = try await deviceManager.getOrCreateCurrentDevice()
            let otherCurrentDevice = try await deviceManager.getOrCreateCurrentDevice()

            // THEN
            #expect(
                currentDevice.stableHashValue == otherCurrentDevice.stableHashValue,
                "Current devices should have identical hash values"
            )
        } catch {
            Issue.record("unable to fetch current device twice: \(error)")
        }
    }
}
