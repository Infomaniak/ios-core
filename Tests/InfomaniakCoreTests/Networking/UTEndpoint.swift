/*
 Infomaniak Core - iOS
 Copyright (C) 2026 Infomaniak Network SA

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

@Suite("Endpoint Tests")
struct UTEndpoint {
    @Test("Plus sign in query values is percent-encoded", arguments: [
        ("john+tag@example.com", "john%2Btag@example.com"),
        ("2026-11-23T10:00:00+01:00", "2026-11-23T10:00:00%2B01:00"),
        ("hello world", "hello%20world")
    ])
    func plusSignIsPercentEncoded(value: String, expectedQueryValue: String) throws {
        let endpoint = Endpoint(host: "example.com", path: "/api", queryItems: [URLQueryItem(name: "value", value: value)])

        let components = try #require(URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false))
        #expect(components.percentEncodedQuery == "value=\(expectedQueryValue)")
        #expect(components.queryItems?.first?.value == value)
    }

    @Test("Endpoint without query items has no query")
    func noQueryItems() {
        #expect(Endpoint(host: "example.com", path: "/api").url.query == nil)
    }
}
