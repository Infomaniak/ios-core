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

#if canImport(UIKit)

import Foundation
import MachO
import UIKit

/// Something to construct a standard Infomaniak User-Agent
public struct UserAgentBuilder {
    
    public init() {
        // META: Keep SonarCloud happy
    }
    
    func modelIdentifier() -> String? {
        if let simulatorModelIdentifier = ProcessInfo()
            .environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine,
                                  count: Int(_SYS_NAMELEN)), encoding: .ascii)?
            .trimmingCharacters(in: .controlCharacters)
    }

    func microarchitecture() -> String? {
        guard let archRaw = NXGetLocalArchInfo().pointee.name else {
            return nil
        }
        return String(cString: archRaw)
    }

    /// The standard infomaniak app user agent
    public var userAgent: String {
        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "x.x.x"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "x"

        let executableName = Bundle.main.bundleIdentifier ?? "com.infomaniak.x"
        let appVersion = "\(release)-\(build)"
        let hardwareDevice = modelIdentifier() ?? "unknownModel"

        let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let OSNameAndVersion =
            "\(UIDevice.current.systemName) \(operatingSystemVersion.majorVersion).\(operatingSystemVersion.minorVersion).\(operatingSystemVersion.patchVersion)"

        let cpuArchitecture = microarchitecture() ?? "unknownArch"

        /// Something like:
        /// `com.infomaniak.mail/1.0.5-1 (iPhone15,2; iOS16.4.0; arm64e)`
        /// `com.infomaniak.mail.ShareExtension/1.0.5-1 (iPhone15,2; iOS16.4.0; arm64e)`
        let userAgent = "\(executableName)/\(appVersion) (\(hardwareDevice); \(OSNameAndVersion); \(cpuArchitecture))"
        return userAgent
    }
}

#endif
