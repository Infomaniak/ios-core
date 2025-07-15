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
import MachO
#if canImport(UIKit)
import UIKit
#endif

public struct MetadataReader: Sendable {
    public init() {
        // META: Keep SonarCloud happy
    }

    public var modelIdentifier: String? {
        #if canImport(UIKit)
        if let simulatorModelIdentifier = ProcessInfo()
            .environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine,
                                  count: Int(_SYS_NAMELEN)), encoding: .ascii)?
            .trimmingCharacters(in: .controlCharacters)
        #else
        macModelIdentifier
        #endif
    }

    public var microarchitecture: String? {
        guard let archRaw = NXGetLocalArchInfo().pointee.name else {
            return nil
        }
        return String(cString: archRaw)
    }

    @MainActor
    public var deviceUUID: String {
        #if canImport(UIKit)
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().emptyUUIDString
        #else
        macHardwareUUID
        #endif
    }

    private var macHardwareUUID: String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPHardwareDataType"]

        let pipe = Pipe()
        task.standardOutput = pipe

        try? task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        guard let output = output,
              let newlineIndex = output.firstIndex(of: "\n"),
              let range = output.range(of: "Hardware UUID: ") else {
            return UUID.emptyUUIDString
        }

        let buffer = output[range.upperBound...]
        guard buffer.count >= UUID.length else {
            return UUID.emptyUUIDString
        }

        let uuid = String(output[range.upperBound...].prefix(UUID.length - 1))
        return uuid
    }
    
    var macModelIdentifier: String? {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        
        var model = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &model, &size, nil, 0)
        
        return String(cString: model)
    }
}

public extension UUID {
    static var emptyUUIDString: String {
        "00000000-0000-0000-0000-000000000000"
    }

    static let length = 37
}
