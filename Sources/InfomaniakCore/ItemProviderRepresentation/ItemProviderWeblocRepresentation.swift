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

/// Something that can provide a `Progress` and an async `Result` in order to make a webloc plist from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderWeblocRepresentation: NSObject, ProgressResultable {
    public enum ErrorDomain: Error, Equatable {
        case unableToLoadURLForObject
    }

    public typealias Success = URL
    public typealias Failure = Error

    /// Track task progress with internal Combine pipe
    private let resultProcessed = PassthroughSubject<Success, Failure>()

    /// Internal observation of the Combine progress Pipe
    private var resultProcessedObserver: AnyCancellable?

    /// Internal Task that wraps the combine result observation
    private var computeResultTask: Task<Success, Failure>?

    private let fileManager = FileManager.default

    public init(from itemProvider: NSItemProvider) throws {
        // Keep compiler happy
        progress = Progress(totalUnitCount: 1)

        super.init()

        progress = itemProvider.loadObject(ofClass: URL.self) { path, error in
            guard error == nil, let path: URL = path else {
                let error: Error = error ?? ErrorDomain.unableToLoadURLForObject
                self.resultProcessed.send(completion: .failure(error))
                return
            }

            // Save the URL as a webloc file (plist)
            let content = ["URL": path.absoluteString]
            
            do {
                @InjectService var pathProvider: AppGroupPathProvidable
                let tmpDirectoryURL = pathProvider.tmpDirectoryURL
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try self.fileManager.createDirectory(at: tmpDirectoryURL, withIntermediateDirectories: true)

                let fileName = path.lastPathComponent
                let targetURL = tmpDirectoryURL.appendingPathComponent("\(fileName).webloc")
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(content)
                try data.write(to: targetURL)

                self.resultProcessed.send(targetURL)
                self.resultProcessed.send(completion: .finished)
            } catch {
                self.resultProcessed.send(completion: .failure(error))
            }
        }

        /// Wrap the Combine pipe to a native Swift Async Task for convenience
        computeResultTask = Task {
            do {
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

            } catch {
                throw error
            }
        }
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