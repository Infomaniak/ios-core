//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

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
        let device = await UserDevice(uid: uuid, appMarketingVersion: "1.0.0", capabilities: [])

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
        let device = await UserDevice(uid: uuid, appMarketingVersion: "1.0.0", capabilities: [])
        let sameDevice = await UserDevice(uid: uuid, appMarketingVersion: "1.0.0", capabilities: [])

        // THEN
        #expect(device.stableHashValue == sameDevice.stableHashValue, "Two devices with same uuid should have same hash")
    }

    @Test("UserDevice hash UnEqual", arguments: [UUID().uuidString])
    func userDeviceHashUnEqual(uuid: String) async throws {
        // WHEN
        let device = await UserDevice(uid: uuid, appMarketingVersion: "1.0.0", capabilities: [])
        let sameDevice = await UserDevice(uid: UUID().uuidString, appMarketingVersion: "1.0.0", capabilities: [])

        // THEN
        #expect(device.stableHashValue != sameDevice.stableHashValue, "Two devices with same uuid should have same hash")
    }

    @Test("UserDevice capabilities encoding", arguments: [UUID().uuidString])
    func userDeviceEncoding(uuid: String) async throws {
        // WHEN
        let device = await UserDevice(uid: uuid, appMarketingVersion: "1.0.0", capabilities: ["2fa"])

        let encodedJson = try JSONEncoder().encode(device)
        let jsonString = String(data: encodedJson, encoding: .utf8) ?? "Encoding failed"

        // THEN
        #expect(jsonString.contains("\"capabilities\":[\"2fa\"]"), "Encoding did not match expectation: \(jsonString)")
    }
}
