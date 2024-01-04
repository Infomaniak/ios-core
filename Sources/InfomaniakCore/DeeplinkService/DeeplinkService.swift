//
//  File.swift
//
//
//  Created by Ambroise Decouttere on 28/12/2023.
//

import Foundation
import InfomaniakDI
import Sentry

@available(iOS 14, *)
public struct DeeplinkService {
    @LazyInjectService private var urlOpener: URLOpenable

    private let group = "group.com.infomaniak"
    private let kdriveAppStore = "https://itunes.apple.com/app/id1482778676"

    public init() {}

    public func shareFileToKdrive(_ url: URL) throws {
        guard let destination = try GroupContainerService.writeToGroupContainer(group: group, file: url) else { return }

        var targetUrl = URLComponents(string: "kdrive-file-sharing://file")
        targetUrl?.queryItems = [URLQueryItem(name: "url", value: destination.path)]
        if let targetAppUrl = targetUrl?.url, urlOpener.canOpen(url: targetAppUrl) {
            urlOpener.openUrl(targetAppUrl)
        } else {
            urlOpener.openUrl(URL(string: "https://itunes.apple.com/app/id1482778676")!)
        }
    }
}
