/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

/// Something that can provide a `Progress` and an async `Result` in order to make a raw text file from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderTextRepresentation: NSObject, ProgressResultable {
    /// Progress increment size
    private static let progressStep: Int64 = 1

    /// Something to transform events to a nice `async Result`
    private let flowToAsync = FlowToAsyncResult<Success>()

    /// Shorthand for default FileManager
    private let fileManager = FileManager.default

    /// Domain specific errors
    public enum ErrorDomain: Error, Equatable {
        case UTINotFound
        case UTINotSupported
        case unknown
    }

    public typealias Success = URL
    public typealias Failure = Error

    public init(from itemProvider: NSItemProvider) throws {
        guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first else {
            throw ErrorDomain.UTINotFound
        }

        progress = Progress(totalUnitCount: Self.progressStep)

        super.init()

        let completionProgress = Progress()
        progress.addChild(completionProgress, withPendingUnitCount: Self.progressStep)

        itemProvider.loadItem(forTypeIdentifier: typeIdentifier) { [self] coding, error in
            guard error == nil,
                  let coding else {
                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendFailure(error ?? ErrorDomain.unknown)
                return
            }

            do {
                // Is String
                guard try !stringHandling(coding, completionProgress: completionProgress) else {
                    return
                }

                // Is Data
                guard try !dataHandling(
                    coding,
                    typeIdentifier: typeIdentifier,
                    completionProgress: completionProgress
                ) else {
                    return
                }

                // Not supported
                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendFailure(ErrorDomain.UTINotSupported)

            } catch {
                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendFailure(error)
                return
            }
        }
    }

    private func stringHandling(_ coding: NSSecureCoding, completionProgress: Progress) throws -> Bool {
        guard let text = coding as? String else {
            // Not matching type, do nothing.
            return false
        }

        let targetURL = try URL.temporaryUniqueFolderURL()
            .appendingPathComponent("\(URL.defaultFileName()).txt")

        try text.write(to: targetURL, atomically: true, encoding: .utf8)

        completionProgress.completedUnitCount += Self.progressStep
        flowToAsync.sendSuccess(targetURL)

        return true
    }

    private func dataHandling(_ coding: NSSecureCoding,
                              typeIdentifier: String,
                              completionProgress: Progress) throws -> Bool {
        guard let data = coding as? Data else {
            // Not matching type, do nothing.
            return false
        }

        guard let uti = UTI(typeIdentifier) else {
            completionProgress.completedUnitCount += Self.progressStep
            flowToAsync.sendFailure(ErrorDomain.UTINotFound)
            return false
        }

        let targetURL = try URL.temporaryUniqueFolderURL()
            .appendingPathComponent("\(URL.defaultFileName()).txt")
            .appendingPathExtension(for: uti)

        try data.write(to: targetURL)

        completionProgress.completedUnitCount += Self.progressStep
        flowToAsync.sendSuccess(targetURL)

        return true
    }

    // MARK: ProgressResultable

    public var progress: Progress

    public var result: Result<URL, Error> {
        get async {
            return await flowToAsync.result
        }
    }
}
