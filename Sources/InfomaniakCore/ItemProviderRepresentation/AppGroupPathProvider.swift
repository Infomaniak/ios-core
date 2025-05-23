/*
 Infomaniak kDrive - iOS App
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
import OSLog

/// Something that can provide a set of common URLs within the app group
///
/// This is shared between all apps of the group initialised with
public protocol AppGroupPathProvidable: AnyObject {
    /// Failable init if app group is not found
    init?(realmRootPath: String, appGroupIdentifier: String)

    /// The directory of the current app group, exists in FS.
    /// Uses the `.completeUntilFirstUserAuthentication` protection policy
    var groupDirectoryURL: URL { get }

    /// The root directory to store the App's Realm files, exists in FS
    var realmRootURL: URL { get }

    /// The import directory, exists in FS
    var importDirectoryURL: URL { get }

    /// The cache directory within the app group, exists in FS
    var cacheDirectoryURL: URL { get }

    /// A temporary directory, exists in FS, implementation should use something akin to `NSTemporaryDirectory`
    var tmpDirectoryURL: URL { get }

    /// Open In Place directory if available
    var openInPlaceDirectoryURL: URL? { get }
}

public final class AppGroupPathProvider: AppGroupPathProvidable {
    private let logger = Logger(category: "AppGroupPathProvider")

    private let fileManager = FileManager.default

    private let realmRootPath: String

    // MARK: public var

    public let groupDirectoryURL: URL

    public lazy var realmRootURL: URL = {
        let drivesURL = groupDirectoryURL.appendingPathComponent(self.realmRootPath, isDirectory: true)
        try? fileManager.createDirectory(
            atPath: drivesURL.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return drivesURL
    }()

    public lazy var importDirectoryURL: URL = {
        let importURL = groupDirectoryURL.appendingPathComponent("import", isDirectory: true)
        try? fileManager.createDirectory(
            atPath: importURL.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return importURL
    }()

    public lazy var cacheDirectoryURL: URL = {
        let cacheURL = groupDirectoryURL.appendingPathComponent("Library/Caches", isDirectory: true)
        try? fileManager.createDirectory(
            atPath: cacheURL.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return cacheURL
    }()

    public lazy var tmpDirectoryURL: URL = {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? fileManager.createDirectory(
            atPath: tmpURL.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return tmpURL
    }()

    public lazy var openInPlaceDirectoryURL: URL? = {
        let openInPlaceURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(".shared", isDirectory: true)
        return openInPlaceURL
    }()

    // MARK: init

    public init?(realmRootPath: String, appGroupIdentifier: String) {
        guard let groupDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            return nil
        }

        do {
            try fileManager.setAttributes(
                [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: groupDirectoryURL.path
            )
        } catch {
            logger.error("[AppGroupPathProvider] failed to protect mandatory path :\(error)")
            return nil
        }

        self.groupDirectoryURL = groupDirectoryURL
        self.realmRootPath = realmRootPath
    }
}
