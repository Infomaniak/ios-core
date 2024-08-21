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

import CocoaLumberjackSwift
import Foundation
import InfomaniakDI

public actor UserProfileStore {
    public typealias UserId = Int

    let preferencesURL: URL
    let storeFileURL: URL

    var profiles: [UserId: UserProfile]?

    public init() {
        @InjectService var appGroupPathProvider: AppGroupPathProvidable
        preferencesURL = appGroupPathProvider.groupDirectoryURL.appendingPathComponent(
            "preferences/",
            isDirectory: true
        )
        storeFileURL = preferencesURL.appendingPathComponent("users.json")
    }

    @discardableResult
    public func updateUserProfile(with apiFetcher: ApiFetcher) async throws -> UserProfile {
        await loadIfNeeded()
        let user = try await apiFetcher.userProfile(ignoreDefaultAvatar: true, dateFormat: .iso8601)
        profiles?[user.id] = user

        await save()

        return user
    }

    public func getUserProfile(id: UserId) async -> UserProfile? {
        await loadIfNeeded()
        return profiles?[id]
    }

    public func removeUserProfile(id: UserId) async {
        profiles?.removeValue(forKey: id)
        await save()
    }

    private func save() async {
        let encoder = JSONEncoder()
        do {
            let usersData = try encoder.encode(profiles)
            try FileManager.default.createDirectory(atPath: preferencesURL.path, withIntermediateDirectories: true)
            try usersData.write(to: storeFileURL)
        } catch {
            DDLogError("[UserProfileStore] Error saving accounts :\(error)")
        }
    }

    private func loadIfNeeded() async {
        guard profiles == nil else {
            return
        }

        profiles = [:]

        let decoder = JSONDecoder()

        do {
            let data = try Data(contentsOf: storeFileURL)
            let savedUsers = try decoder.decode([UserId: UserProfile].self, from: data)

            profiles = savedUsers
        } catch {
            DDLogError("[UserProfileStore] Error loading accounts :\(error)")
        }
    }
}
