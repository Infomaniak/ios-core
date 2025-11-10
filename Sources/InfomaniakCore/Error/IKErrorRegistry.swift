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

public enum HandledErrorCode {
    case unknown
    case unknownApiError
    case apiError(String)
    case serverError
    case localError(String)

    public var rawValue: String {
        switch self {
        case .unknown:
            return "unknown"
        case .unknownApiError:
            return "unknown_api"
        case .apiError(let string):
            return string
        case .serverError:
            return "server_error"
        case .localError(let string):
            return string
        }
    }
}

public struct HandledError {
    public let code: HandledErrorCode
    public let localizedMessage: String
    public let shouldDisplay: Bool

    public init(code: HandledErrorCode,
                localizedMessage: String,
                shouldDisplay: Bool) {
        self.code = code
        self.localizedMessage = localizedMessage
        self.shouldDisplay = shouldDisplay
    }
}

public struct IKErrorRegistry {
    public let apiHandledErrors: [String: HandledError]

    public let unknownHandledError: HandledError
    public let unknownApiHandledError: HandledError
    public let serverHandledError: HandledError
    public let networkHandledError: HandledError

    public init(unknownHandledError: HandledError,
                unknownApiHandledError: HandledError,
                serverHandledError: HandledError,
                networkHandledError: HandledError,
                apiHandledErrors: [HandledError]) {
        self.unknownHandledError = unknownHandledError
        self.unknownApiHandledError = unknownApiHandledError
        self.serverHandledError = serverHandledError
        self.networkHandledError = networkHandledError

        self.apiHandledErrors = apiHandledErrors.reduce(into: [String: HandledError]()) { partialResult, error in
            #if DEBUG
            if partialResult[error.code.rawValue] != nil {
                fatalError("Error code \(error.code.rawValue) was registered twice this can lead to unexpected behaviour")
            }
            #endif
            partialResult[error.code.rawValue] = error
        }
    }

    public func unknownError(underlyingError: Error?, shouldDisplay: Bool) -> LocalError {
        return LocalError(
            code: unknownHandledError.code.rawValue,
            localizedMessage: unknownHandledError.localizedMessage,
            underlyingError: underlyingError,
            shouldDisplay: shouldDisplay
        )
    }

    public func networkError(underlyingError: Error?) -> LocalError {
        return LocalError(
            code: networkHandledError.code.rawValue,
            localizedMessage: networkHandledError.localizedMessage,
            underlyingError: underlyingError,
            shouldDisplay: networkHandledError.shouldDisplay
        )
    }

    public func serverError(statusCode: Int) -> ServerError {
        return ServerError(
            code: serverHandledError.code.rawValue,
            statusCode: statusCode,
            localizedMessage: serverHandledError.localizedMessage,
            shouldDisplay: serverHandledError.shouldDisplay
        )
    }

    public func apiError(_ decodedApiError: DecodableApiError, statusCode: Int) -> ApiError {
        guard let handledApiError = apiHandledErrors[decodedApiError.code] else {
            return ApiError(
                code: HandledErrorCode.unknownApiError.rawValue,
                originalCode: decodedApiError.code,
                description: decodedApiError.description,
                statusCode: statusCode,
                localizedMessage: unknownApiHandledError.localizedMessage,
                shouldDisplay: unknownApiHandledError.shouldDisplay
            )
        }

        return ApiError(
            code: handledApiError.code.rawValue,
            originalCode: decodedApiError.code,
            description: decodedApiError.description,
            statusCode: statusCode,
            localizedMessage: handledApiError.localizedMessage,
            shouldDisplay: handledApiError.shouldDisplay
        )
    }
}
