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

public struct UserDevice: Sendable, Hashable {
    static let metadataReader = MetadataReader()

    let brand = "Apple"
    let model: String?
    let platform: AttachDeviceOS
    let type: AttachDeviceType
    let uid: String

    public init(uid: String) async {
        self.uid = uid
        model = Self.metadataReader.modelIdentifier
        platform = await AttachDeviceOS.current
        type = await AttachDeviceType.current
    }
}

extension UserDevice {
    var asParameters: [String: String] {
        var parameters = ["platform": platform.rawValue,
                          "type": type.rawValue,
                          "uid": uid,
                          "brand": brand]

        if let model, !model.isEmpty {
            parameters["model"] = model
        }

        return parameters
    }
}

public enum AttachDeviceType: String, Sendable, Hashable {
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

public enum AttachDeviceOS: String, Sendable, Hashable {
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
