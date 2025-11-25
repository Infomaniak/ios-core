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

import Foundation
import MachO
#if canImport(UIKit)
import UIKit
#endif

public struct MetadataReader: Sendable {
    public init() {
        // META: Keep SonarCloud happy
    }

    public var microarchitecture: String? {
        guard let archRaw = NXGetLocalArchInfo().pointee.name else {
            return nil
        }
        return String(cString: archRaw)
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

    var macModelIdentifier: String? {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        var model = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &model, &size, nil, 0)

        return String(cString: model)
    }
}
