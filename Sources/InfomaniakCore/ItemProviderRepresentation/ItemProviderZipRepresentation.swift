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

/// Something that can provide a `Progress` and an async `Result` in order to make a zip from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderZipRepresentation: NSObject, ProgressResultable {
    /// Coordinator for file operations
    let coordinator = NSFileCoordinator()

    /// Progress increment size
    private static let progressStep: Int64 = 1

    /// Number of steps to complete the task
    private static let totalSteps: Int64 = 2

    /// Something to transform events to a nice `async Result`
    private let flowToAsync = FlowToAsyncResult<Success>()

    /// Shorthand for default FileManager
    private let fileManager = FileManager.default

    /// Domain specific errors
    public enum ErrorDomain: Error, Equatable {
        case unableToLoadURLForObject
        case notADirectory
    }

    public typealias Success = URL
    public typealias Failure = Error

    public init(from itemProvider: NSItemProvider) throws {
        // It must be a directory for the OS to zip it for us, a file returns a file
        guard itemProvider.underlyingType == .isDirectory else {
            throw ErrorDomain.notADirectory
        }

        progress = Progress(totalUnitCount: Self.totalSteps)

        super.init()

        let completionProgress = Progress(totalUnitCount: Self.progressStep)
        progress.addChild(completionProgress, withPendingUnitCount: Self.progressStep)
        
        let loadURLProgress = itemProvider.loadObject(ofClass: URL.self) { [self] path, error in
            guard error == nil, let path: URL = path else {
                flowToAsync.sendFailure(error ?? ErrorDomain.unableToLoadURLForObject)
                completionProgress.completedUnitCount += Self.progressStep
                return
            }

            // Get a NSProgress on file copy is hard ~>
            // https://developer.apple.com/forums/thread/114001?answerId=350635022#350635022
            // > If you’d like to see such support [ie. for NSProgress] added in the future, I encourage you to file an
            // enhancement request

            // compress content of folder and move it somewhere we can safely store it for upload
            var error: NSError?
            coordinator.coordinate(readingItemAt: path, options: [.forUploading], error: &error) { zipURL in
                defer {
                    completionProgress.completedUnitCount += Self.progressStep
                }

                do {
                    @InjectService var pathProvider: AppGroupPathProvidable
                    let tmpDirectoryURL = pathProvider.tmpDirectoryURL
                        .appendingPathComponent(UUID().uuidString, isDirectory: true)
                    try self.fileManager.createDirectory(at: tmpDirectoryURL, withIntermediateDirectories: true)

                    let fileName = path.lastPathComponent
                    let targetURL = tmpDirectoryURL.appendingPathComponent("\(fileName).zip")

                    try self.fileManager.moveItem(at: zipURL, to: targetURL)
                    self.flowToAsync.sendSuccess(targetURL)
                } catch {
                    self.flowToAsync.sendFailure(error)
                }
            }
        }
        progress.addChild(loadURLProgress, withPendingUnitCount: Self.progressStep)
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
