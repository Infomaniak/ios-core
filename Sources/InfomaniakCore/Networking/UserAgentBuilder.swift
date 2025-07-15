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
#if canImport(UIKit)
import UIKit
#endif

/// Something to construct a standard Infomaniak User-Agent
public struct UserAgentBuilder {
    private let metadataReader = MetadataReader()

    public init() {
        // META: Keep SonarCloud happy
    }

    /// The standard Infomaniak app user agent
    public var userAgent: String {
        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "x.x.x"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "x"

        let executableName = Bundle.main.bundleIdentifier ?? "com.infomaniak.x"
        let appVersion = "\(release)-\(build)"
        let hardwareDevice = metadataReader.modelIdentifier ?? "unknownModel"

        let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        #if canImport(UIKit)
        let osName = UIDevice.current.systemName
        #else
        let osName = "macOS"
        #endif
        let operatingSystemNameAndVersion =
            "\(osName) \(operatingSystemVersion.majorVersion).\(operatingSystemVersion.minorVersion).\(operatingSystemVersion.patchVersion)"

        let cpuArchitecture = metadataReader.microarchitecture ?? "unknownArch"

        /// Something like:
        /// `com.infomaniak.mail/1.0.5-1 (iPhone15,2; iOS16.4.0; arm64e)`
        /// `com.infomaniak.mail.ShareExtension/1.0.5-1 (iPhone15,2; iOS16.4.0; arm64e)`
        return "\(executableName)/\(appVersion) (\(hardwareDevice); \(operatingSystemNameAndVersion); \(cpuArchitecture))"
    }
}
