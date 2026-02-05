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

public extension AppIdentifierBuilder {
    static let ikAppIdentifierBuilder = AppIdentifierBuilder(teamId: "864VDCS2QY")
    static let driveKeychainIdentifier = ikAppIdentifierBuilder.keychainAccessGroupFor(identifier: "com.infomaniak.drive")
    static let mailKeychainIdentifier = ikAppIdentifierBuilder.keychainAccessGroupFor(identifier: "com.infomaniak.mail")
    static let euriaKeychainIdentifier = ikAppIdentifierBuilder.keychainAccessGroupFor(identifier: "com.infomaniak.euria")
    static let authenticatorKeychainIdentifier = ikAppIdentifierBuilder
        .keychainAccessGroupFor(identifier: "com.infomaniak.authenticator")
    static let swissTransferKeychainIdentifier = ikAppIdentifierBuilder
        .keychainAccessGroupFor(identifier: "com.infomaniak.swisstransfer")

    static let knownAppKeychainIdentifiers = [
        driveKeychainIdentifier,
        mailKeychainIdentifier,
        euriaKeychainIdentifier,
        authenticatorKeychainIdentifier,
        swissTransferKeychainIdentifier
    ]
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
