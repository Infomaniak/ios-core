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
}
