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

import Combine
import Foundation
import InfomaniakDI

/// Something that can provide a `Progress` and an async `Result` in order to make a raw text file from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderTextRepresentation: NSObject, ProgressResultable {
    public enum ErrorDomain: Error, Equatable {
        case UTINotFound
        case UTINotSupported
        case unknown
    }

    public typealias Success = URL
    public typealias Failure = Error

    private static let progressStep: Int64 = 1

    /// Track task progress with internal Combine pipe
    private let resultProcessed = PassthroughSubject<Success, Failure>()

    /// Internal observation of the Combine progress Pipe
    private var resultProcessedObserver: AnyCancellable?

    /// Internal Task that wraps the combine result observation
    private var computeResultTask: Task<Success, Failure>?

    private let fileManager = FileManager.default

    public init(from itemProvider: NSItemProvider) throws {
        guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first else {
            throw ErrorDomain.UTINotFound
        }

        // Keep compiler happy
        progress = Progress(totalUnitCount: 1)

        super.init()

        let childProgress = Progress()
        progress.addChild(childProgress, withPendingUnitCount: Self.progressStep)

        itemProvider.loadItem(forTypeIdentifier: typeIdentifier) { coding, error in
            defer {
                childProgress.completedUnitCount += Self.progressStep
            }

            guard error == nil,
                  let coding else {
                self.resultProcessed.send(completion: .failure(error ?? ErrorDomain.unknown))
                return
            }

            do {
                // Build dedicated storage path
                @InjectService var pathProvider: AppGroupPathProvidable
                let temporaryURL = pathProvider.tmpDirectoryURL
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try self.fileManager.createDirectory(at: temporaryURL, withIntermediateDirectories: true)

                // Is String
                guard try !self.stringHandling(coding, temporaryURL: temporaryURL) else {
                    return
                }

                // Is Data
                guard try !self.dataHandling(coding, typeIdentifier: typeIdentifier, temporaryURL: temporaryURL) else {
                    return
                }

                // Not supported
                self.resultProcessed.send(completion: .failure(ErrorDomain.UTINotSupported))

            } catch {
                self.resultProcessed.send(completion: .failure(error))
                return
            }
        }

        /// Wrap the Combine pipe to a native Swift Async Task for convenience
        computeResultTask = Task {
            let result: URL = try await withCheckedThrowingContinuation { continuation in
                self.resultProcessedObserver = resultProcessed.sink { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    self.resultProcessedObserver?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
            }

            return result
        }
    }

    private func stringHandling(_ coding: NSSecureCoding, temporaryURL: URL) throws -> Bool {
        guard let text = coding as? String else {
            return false
        }
        let targetURL = temporaryURL.appendingPathComponent("\(UUID().uuidString).txt")

        try text.write(to: targetURL, atomically: true, encoding: .utf8)
        resultProcessed.send(targetURL)
        resultProcessed.send(completion: .finished)

        return true
    }

    private func dataHandling(_ coding: NSSecureCoding, typeIdentifier: String, temporaryURL: URL) throws -> Bool {
        guard let data = coding as? Data else {
            return false
        }

        guard let uti = UTI(typeIdentifier) else {
            resultProcessed.send(completion: .failure(ErrorDomain.UTINotFound))
            return false
        }

        let targetURL = temporaryURL
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(for: uti)

        try data.write(to: targetURL)
        resultProcessed.send(targetURL)
        resultProcessed.send(completion: .finished)

        return true
    }

    // MARK: Public

    public var progress: Progress

    public var result: Result<URL, Error> {
        get async {
            guard let computeResultTask else {
                fatalError("This never should be nil")
            }

            return await computeResultTask.result
        }
    }
}

#endif
