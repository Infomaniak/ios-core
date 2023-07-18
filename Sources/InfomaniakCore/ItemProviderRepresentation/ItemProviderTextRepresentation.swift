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

#if canImport(MobileCoreServices)

import Foundation
import InfomaniakDI

/// Something that can provide a `Progress` and an async `Result` in order to make a raw text file from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderTextRepresentation: NSObject, ProgressResultable {
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

    private static let progressStep: Int64 = 1

    public init(from itemProvider: NSItemProvider) throws {
        guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first else {
            throw ErrorDomain.UTINotFound
        }

        // Keep compiler happy
        progress = Progress(totalUnitCount: 1)

        super.init()

        let childProgress = Progress()
        progress.addChild(childProgress, withPendingUnitCount: Self.progressStep)

        itemProvider.loadItem(forTypeIdentifier: typeIdentifier) { [self] coding, error in
            defer {
                childProgress.completedUnitCount += Self.progressStep
            }

            guard error == nil,
                  let coding else {
                flowToAsync.send(completion: .failure(error ?? ErrorDomain.unknown))
                return
            }

            do {
                // Build dedicated storage path
                @InjectService var pathProvider: AppGroupPathProvidable
                let temporaryURL = pathProvider.tmpDirectoryURL
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try fileManager.createDirectory(at: temporaryURL, withIntermediateDirectories: true)

                // Is String
                guard try !stringHandling(coding, temporaryURL: temporaryURL) else {
                    return
                }

                // Is Data
                guard try !dataHandling(coding, typeIdentifier: typeIdentifier, temporaryURL: temporaryURL) else {
                    return
                }

                // Not supported
                flowToAsync.send(completion: .failure(ErrorDomain.UTINotSupported))

            } catch {
                flowToAsync.send(completion: .failure(error))
                return
            }
        }
    }

    private func stringHandling(_ coding: NSSecureCoding, temporaryURL: URL) throws -> Bool {
        guard let text = coding as? String else {
            return false
        }
        let targetURL = temporaryURL.appendingPathComponent("\(UUID().uuidString).txt")

        try text.write(to: targetURL, atomically: true, encoding: .utf8)
        flowToAsync.send(targetURL)

        return true
    }

    private func dataHandling(_ coding: NSSecureCoding, typeIdentifier: String, temporaryURL: URL) throws -> Bool {
        guard let data = coding as? Data else {
            return false
        }

        guard let uti = UTI(typeIdentifier) else {
            flowToAsync.send(completion: .failure(ErrorDomain.UTINotFound))
            return false
        }

        let targetURL = temporaryURL
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(for: uti)

        try data.write(to: targetURL)
        flowToAsync.send(targetURL)

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

#endif
