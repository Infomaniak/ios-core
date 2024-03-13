/*
 Infomaniak Core - iOS
 Copyright (C) 2024 Infomaniak Network SA

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
import OSInfo

public enum CorePlatform {

    /// Unified version descriptor for IK platform apps
    public static func appVersionLabel(fallbackAppName: String) -> String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String? ?? fallbackAppName
        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? ?? "x.x"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String? ?? "x"
        let betaRelease = Bundle.main.isRunningInTestFlight ? "beta" : ""

        // Returns "macOS" on unmodified iOS and catalyst apps running on macOS
        let systemName = OS.current.name

        return "\(appName) \(systemName) version \(release)-\(betaRelease)\(build)"
    }
}
