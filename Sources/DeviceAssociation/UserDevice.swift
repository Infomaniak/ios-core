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
#if canImport(UIKit)
import UIKit
#endif

public struct UserDevice: Sendable, Encodable {
    public let uid: String
    public let brand = "Apple"
    public let model: String?
    public let platform: AttachDeviceOS
    public let type: AttachDeviceType

    public let appMarketingVersion: String
    public let capabilities: [Capability]

    enum CodingKeys: String, CodingKey {
        case uid
        case brand
        case model
        case platform
        case type
        case appMarketingVersion = "version"
        case capabilities
    }

    public init(uid: String, appMarketingVersion: String, capabilities: [Capability]) async {
        self.uid = uid
        model = MetadataReader().modelIdentifier
        platform = AttachDeviceOS.current
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
        #if targetEnvironment(macCatalyst) || os(macOS)
        return .computer
        #elseif canImport(UIKit)
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

    static var current: AttachDeviceOS {
        #if targetEnvironment(macCatalyst) || os(macOS)
        return .macos
        #elseif canImport(UIKit)
        return .ios
        #else
        return .macos
        #endif
    }
}
