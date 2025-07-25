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

@Suite("UTUserDevice")
struct UTUserDevice {
    @Test("Generate a UserDevice representation", arguments: [UUID().uuidString])
    func userDeviceInit(uuid: String) async throws {
        // WHEN
        let device = await UserDevice(uid: uuid)

        // THEN
        #expect(device.uid == uuid)
        #expect(device.brand == "Apple")
        guard let model = device.model else {
            Issue.record("The apple model reading should work on mac an iPhone/iPad but is nil")
            return
        }
        #expect(model.contains(","))
    }

    @Test("UserDevice hash stability", arguments: [UUID().uuidString])
    func userDeviceHashStability(uuid: String) async throws {
        // WHEN
        let device = await UserDevice(uid: uuid)
        let sameDevice = await UserDevice(uid: uuid)

        // THEN
        #expect(device.hashValue == sameDevice.hashValue, "Two devices with same uuid should have same hash")
    }

    @Test("UserDevice hash UnEqual", arguments: [UUID().uuidString])
    func userDeviceHashUnEqual(uuid: String) async throws {
        // WHEN
        let device = await UserDevice(uid: uuid)
        let sameDevice = await UserDevice(uid: UUID().uuidString)

        // THEN
        #expect(device.hashValue != sameDevice.hashValue, "Two devices with same uuid should have same hash")
    }
}
