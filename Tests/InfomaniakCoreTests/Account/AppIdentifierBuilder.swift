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
import Testing

@Suite("UTAppIdentifierBuilder")
struct UTAppIdentifierBuilder {
    @Test(
        "Keychain access group should always start with team identifier and end with the identifier",
        arguments: ["com.infomaniak.test"]
    )
    func keychain(identifier: String) throws {
        let teamId = "TEAMID"
        let appIdentifierBuilder = AppIdentifierBuilder(teamId: teamId)

        #expect(appIdentifierBuilder.keychainAccessGroupFor(identifier: identifier).hasPrefix(teamId + "."))
        #expect(appIdentifierBuilder.keychainAccessGroupFor(identifier: identifier).hasSuffix(identifier))
    }

    @Test("App group should always start with group. and end with the identifier", arguments: ["com.infomaniak.test"])
    func appGroup(identifier: String) throws {
        let appIdentifierBuilder = AppIdentifierBuilder(teamId: "TEAMID")

        #expect(appIdentifierBuilder.appGroupFor(identifier: identifier).hasPrefix("group."))
        #expect(appIdentifierBuilder.appGroupFor(identifier: identifier).hasSuffix(identifier))
    }
}
