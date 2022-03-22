/*
 Infomaniak Core - iOS
 Copyright (C) 2021 Infomaniak Network SA

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

// MARK: - Type definition

public enum ApiEnvironment {
    case prod, preprod

    public static var current = ApiEnvironment.prod

    public var host: String {
        switch self {
        case .prod:
            return "infomaniak.com"
        case .preprod:
            return "preprod.dev.infomaniak.ch"
        }
    }

    public var apiHost: String {
        return "api.\(host)"
    }

    public var managerHost: String {
        return "manager.\(host)"
    }
}

public struct Endpoint {
    public let path: String
    public let queryItems: [URLQueryItem]?
    public let apiEnvironment: ApiEnvironment

    public var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = apiEnvironment.apiHost
        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            fatalError("Invalid endpoint URL: \(self)")
        }
        return url
    }

    public init(path: String, queryItems: [URLQueryItem]? = nil, apiEnvironment: ApiEnvironment = .current) {
        self.path = path
        self.queryItems = queryItems
        self.apiEnvironment = apiEnvironment
    }

    public func appending(path: String, queryItems: [URLQueryItem]? = nil) -> Endpoint {
        return Endpoint(path: self.path + path, queryItems: queryItems, apiEnvironment: apiEnvironment)
    }
}

// MARK: - Endpoints

public extension Endpoint {
    static var baseV1: Endpoint {
        return Endpoint(path: "/1")
    }

    static var baseV2: Endpoint {
        return Endpoint(path: "/2")
    }

    static var profile: Endpoint {
        return .baseV2.appending(path: "/profile", queryItems: [URLQueryItem(name: "with", value: "emails,phones")])
    }

    static var organisationAccounts: Endpoint {
        return .baseV1.appending(path: "/account", queryItems: [
            URLQueryItem(name: "with", value: "logo"),
            URLQueryItem(name: "order_by", value: "name")
        ])
    }
}