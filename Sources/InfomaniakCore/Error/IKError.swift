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

public protocol IKError: Error, LocalizedError, Equatable {
    var code: String { get }
    var localizedMessage: String { get }
    var underlyingError: Error? { get }
    var shouldDisplay: Bool { get }
}

public extension IKError {
    var shouldDisplay: Bool {
        return false
    }

    var localizedDescription: String {
        return localizedMessage
    }

    var errorDescription: String {
        return localizedMessage
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.code == rhs.code
    }
}

public struct ApiError: IKError {
    public let code: String
    public let originalCode: String?
    public let description: String
    public let statusCode: Int
    public let localizedMessage: String
    public let underlyingError: Error? = nil
    public let shouldDisplay: Bool

    public init(
        code: String,
        originalCode: String?,
        description: String,
        statusCode: Int,
        localizedMessage: String,
        shouldDisplay: Bool
    ) {
        self.code = code
        self.originalCode = originalCode
        self.description = description
        self.statusCode = statusCode
        self.localizedMessage = localizedMessage
        self.shouldDisplay = shouldDisplay
    }
}

extension ApiError: CustomNSError {
    public static var errorDomain = "com.infomaniak.ApiError"
    public var errorUserInfo: [String: Any] {
        return ["code": code, "description": description]
    }
}

public struct ServerError: IKError {
    public let code: String
    public let statusCode: Int
    public let localizedMessage: String
    public let underlyingError: Error? = nil
    public let shouldDisplay: Bool

    public init(code: String, statusCode: Int, localizedMessage: String, shouldDisplay: Bool) {
        self.code = code
        self.statusCode = statusCode
        self.localizedMessage = localizedMessage
        self.shouldDisplay = shouldDisplay
    }
}

public struct LocalError: IKError {
    public let code: String
    public let localizedMessage: String
    public let underlyingError: Error?
    public let shouldDisplay: Bool

    public init(code: String, localizedMessage: String, underlyingError: Error?, shouldDisplay: Bool) {
        self.code = code
        self.localizedMessage = localizedMessage
        self.underlyingError = underlyingError
        self.shouldDisplay = shouldDisplay
    }
}
