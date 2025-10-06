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
import InfomaniakCore
#if canImport(UIKit)
import UIKit
#endif

public typealias Capability = String

public struct UserDevice: Sendable, Encodable {
    public let uid: String
    public let brand = "Apple"
    public let model: String?
    public let platform: AttachDeviceOS
    public let type: AttachDeviceType

    public let appMarketingVersion: String
    public let capabilities: [Capability]

    public init(uid: String, appMarketingVersion: String, capabilities: [Capability]) async {
        self.uid = uid
        model = MetadataReader().modelIdentifier
        platform = await AttachDeviceOS.current
        type = await AttachDeviceType.current
        self.appMarketingVersion = appMarketingVersion
        self.capabilities = capabilities
    }

    var stableHashValue: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        guard let jsonData = try? encoder.encode(self),
              let jsonDataString = String(data: jsonData, encoding: .utf8) else {
            return ""
        }

        return jsonDataString
    }
}

public enum AttachDeviceType: String, Encodable, Sendable {
    case computer
    case phone
    case tablet

    @MainActor static var current: AttachDeviceType {
        #if canImport(UIKit)
        let deviceType = UIDevice.current.userInterfaceIdiom
        switch deviceType {
        case .phone:
            return .phone
        case .pad:
            return .tablet
        default:
            return .computer
        }
        #else
        return .computer
        #endif
    }
}

public enum AttachDeviceOS: String, Encodable, Sendable {
    case ios
    case macos

    @MainActor static var current: AttachDeviceOS {
        #if canImport(UIKit)
        let deviceType = UIDevice.current.userInterfaceIdiom
        switch deviceType {
        case .phone, .pad:
            return .ios
        default:
            return .macos
        }
        #else
        return .macos
        #endif
    }
}
