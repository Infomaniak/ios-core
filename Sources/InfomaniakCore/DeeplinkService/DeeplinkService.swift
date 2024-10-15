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

public struct DeeplinkService {
    @LazyInjectService private var urlOpener: URLOpenable

    private let group = "group.com.infomaniak"
    private let kdriveAppStore = "https://itunes.apple.com/app/id1482778676"

    public init() { /* Empty on purpose */ }

    @available(*, deprecated, message: "Use shareFilesToKdrive([URL]) instead")
    public func shareFileToKdrive(_ url: URL) throws {
        try shareFilesToKdrive([url])
    }

    public func shareFilesToKdrive(_ urls: [URL]) throws {
        let destinations = try urls.compactMap { url in
            try GroupContainerService.writeToGroupContainer(group: group, file: url)
        }
        var targetUrl = URLComponents(string: "kdrive-file-sharing://file")
        targetUrl?.queryItems = destinations.map { destination in
            URLQueryItem(name: "url", value: destination.path)
        }

        if let targetAppUrl = targetUrl?.url, urlOpener.canOpen(url: targetAppUrl) {
            urlOpener.openUrl(targetAppUrl)
        } else {
            urlOpener.openUrl(URL(string: "https://itunes.apple.com/app/id1482778676")!)
        }
    }
}
