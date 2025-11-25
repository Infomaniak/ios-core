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

public extension AppIdentifierBuilder {
    static let ikAppIdentifierBuilder = AppIdentifierBuilder(teamId: "864VDCS2QY")
    static let driveKeychainIdentifier = ikAppIdentifierBuilder.keychainAccessGroupFor(identifier: "com.infomaniak.drive")
    static let mailKeychainIdentifier = ikAppIdentifierBuilder.keychainAccessGroupFor(identifier: "com.infomaniak.mail")
    static let euriaKeychainIdentifier = ikAppIdentifierBuilder.keychainAccessGroupFor(identifier: "com.infomaniak.euria")

    static let knownAppKeychainIdentifiers = [driveKeychainIdentifier, mailKeychainIdentifier, euriaKeychainIdentifier]
}

public struct AppIdentifierBuilder: Sendable {
    public let teamId: String

    /// - Parameter teamId: Team ID of the Apple Developer account eg. For IK 864VDCS2QY. (this ID is public)
    public init(teamId: String) {
        self.teamId = teamId
    }

    /// Construct a valid keychain access group.
    /// - Parameter identifier: The identifier declared in the entitlement file (Keychain Sharing section).
    /// - Returns: An access group ready for use in by the Keychain as kSecAttrAccessGroup.
    public func keychainAccessGroupFor(identifier: String) -> String {
        "\(teamId).\(identifier)"
    }

    /// Construct a valid app group identifier.
    /// - Parameter identifier: The identifier declared in the entitlement file (App Groups section).
    /// - Returns: An app group ready for use with FileManager.containerURL(forSecurityApplicationGroupIdentifier: )
    public func appGroupFor(identifier: String) -> String {
        "group.\(identifier)"
    }
}
