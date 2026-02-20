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

import Alamofire
import Foundation

public struct UserAgentAdapter: RequestAdapter {
    public static let userAgentKey = "User-Agent"
    let userAgentValue: String

    public init() {
        userAgentValue = UserAgentBuilder().userAgent
    }

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Alamofire.Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var adaptedRequest = urlRequest
        adaptedRequest.headers.remove(name: Self.userAgentKey)
        adaptedRequest.headers.add(name: Self.userAgentKey, value: userAgentValue)

        completion(.success(adaptedRequest))
    }
}
