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
import Sentry

public enum SentryDebug {
    enum Category {
        static let fileMetadata = "FileMetadata"
        static let networking = "Networking"
    }

    // MARK: FileMetadata

    /// add a Breadcrumb for FileMetadata errors
    static func fileMetadataBreadcrumb(caller: String = #function, _ metadata: [String: Any]) {
        let breadcrumb = Breadcrumb(level: .error, category: Category.fileMetadata)
        breadcrumb.message = caller
        breadcrumb.data = metadata
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    public static func httpRequestBreadcrumb(requestId: String?, url: URL, method: String, statusCode: Int?) {
        let breadcrumb = Breadcrumb(level: .info, category: Category.networking)
        breadcrumb.type = "http"
        breadcrumb.message = ""

        var data = [
            "url": url.absoluteString,
            "method": method,
            "status_code": statusCode ?? -1
        ] as [String: Any]

        if let requestId {
            data["request_id"] = requestId
        }

        breadcrumb.data = data

        SentrySDK.addBreadcrumb(breadcrumb)
    }

    public static func httpResponseBreadcrumb(urlRequest: URLRequest?, urlResponse: HTTPURLResponse?) {
        guard let url = urlRequest?.url,
              let method = urlRequest?.httpMethod else { return }

        httpRequestBreadcrumb(
            requestId: urlResponse?.value(forHTTPHeaderField: "x-request-id"),
            url: url,
            method: method,
            statusCode: urlResponse?.statusCode
        )
    }
}
