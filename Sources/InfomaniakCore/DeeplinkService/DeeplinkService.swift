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

import Foundation
import InfomaniakDI
import Sentry

public enum KDriveFileSharingConstants {
    public static let appGroupIdentifier = "group.com.infomaniak"
    public static let scheme = "kdrive-file-sharing"
    public static let host = "file"
    public static let urlQueryItemName = "url"
    public static let handoffPathComponents = ["Library", "Caches", "file-sharing"]
    public static let maximumFileCount = 100

    public static func handoffDirectoryURL(in sharedContainerURL: URL) -> URL {
        return handoffPathComponents.reduce(sharedContainerURL) { url, component in
            url.appendingPathComponent(component, isDirectory: true)
        }
    }
}

public struct DeeplinkService {
    @LazyInjectService private var urlOpener: URLOpenable

    private let kdriveAppStore = URL(string: "https://itunes.apple.com/app/id1482778676")!

    public init() { /* Empty on purpose */ }

    @available(*, deprecated, message: "Use shareFilesToKdrive([URL]) instead")
    public func shareFileToKdrive(_ url: URL) throws {
        try shareFilesToKdrive([url])
    }

    public func shareFilesToKdrive(_ urls: [URL]) throws {
        guard !urls.isEmpty, urls.count <= KDriveFileSharingConstants.maximumFileCount else {
            throw GroupContainerService.Error.invalidFileCount
        }

        let destinations = try urls.map { url in
            try GroupContainerService.writeToGroupContainer(group: KDriveFileSharingConstants.appGroupIdentifier, file: url)
        }
        var targetUrl = URLComponents()
        targetUrl.scheme = KDriveFileSharingConstants.scheme
        targetUrl.host = KDriveFileSharingConstants.host
        targetUrl.queryItems = destinations.map { destination in
            URLQueryItem(name: KDriveFileSharingConstants.urlQueryItemName, value: destination.path)
        }

        if let targetAppUrl = targetUrl.url, urlOpener.canOpen(url: targetAppUrl) {
            urlOpener.openUrl(targetAppUrl)
        } else {
            urlOpener.openUrl(kdriveAppStore)
        }
    }
}
