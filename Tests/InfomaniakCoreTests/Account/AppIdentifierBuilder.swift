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
