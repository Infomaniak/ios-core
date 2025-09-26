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

public enum InfomaniakError: Error {
    case apiError(ApiError)
    case serverError(statusCode: Int)
}

/// An  api error for `InfomaniakLogin` form
@objc public class LoginApiError: NSObject, Codable {
    @objc public let error: String
    @objc public let errorDescription: String?
}

public protocol ErrorWithCode: Error {
    var code: String { get }
}

open class ApiError: Codable, Error, ErrorWithCode {
    public var code: String
    public var description: String
}

extension ApiError: CustomNSError {
    public static var errorDomain = "com.infomaniak.ApiError"
    public var errorUserInfo: [String: Any] {
        return ["code": code, "description": description]
    }
}
