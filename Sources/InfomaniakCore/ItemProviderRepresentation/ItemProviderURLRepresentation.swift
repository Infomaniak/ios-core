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

/// Something that provides an URL to a usable recourse
///
/// If the URL represents a local file, the file is copied, else it generates a .webloc
///
/// Provides a `Progress` and an async `Result`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderURLRepresentation: NSObject, ProgressResultable {
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
    }

    public typealias Success = URL
    public typealias Failure = Error

    public init(from itemProvider: NSItemProvider) throws {
        progress = Progress(totalUnitCount: Self.totalSteps)

        super.init()

        let completionProgress = Progress(totalUnitCount: Self.progressStep)
        progress.addChild(completionProgress, withPendingUnitCount: Self.progressStep)

        let loadURLProgress = itemProvider.loadObject(ofClass: URL.self) { [self] url, error in
            guard error == nil, let url: URL = url else {
                let error: Error = error ?? ErrorDomain.unableToLoadURLForObject
                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendFailure(error)
                return
            }

            do {
                // Check if the URL points to a local file
                guard try !localURLHandling(url, completionProgress: completionProgress) else {
                    return
                }

                // Fallback to create a .webloc that point to an external resource
                try weblocURLHandling(url, completionProgress: completionProgress)
                
            } catch {
                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendFailure(error)
            }
        }
        progress.addChild(loadURLProgress, withPendingUnitCount: Self.progressStep)
    }
    
    /// Save the URL as a webloc file (plist)
    private func weblocURLHandling(_ url: URL, completionProgress: Progress) throws {
        let content = ["URL": url.absoluteString]

        let currentName = (url.lastPathComponent as NSString).deletingPathExtension
        let fileName: String
        if currentName.isEmpty {
            fileName = "\(URL.defaultFileName()).webloc"
        } else {
            fileName = "\(currentName).webloc"
        }

        let targetURL = try URL.temporaryUniqueFolderURL().appendingPathComponent(fileName)
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(content)
        try data.write(to: targetURL)

        completionProgress.completedUnitCount += Self.progressStep
        flowToAsync.sendSuccess(targetURL)
    }
    
    /// Move a local file for later use
    private func localURLHandling(_ url: URL, completionProgress: Progress) throws -> Bool {
        // If the URL point to a local path, we must handle it as a standard file
        guard fileManager.fileExists(atPath: url.path) else {
            return false
        }

        let fileName = url.lastPathComponent.isEmpty ? URL.defaultFileName() : url.lastPathComponent
        let targetURL = try URL.temporaryUniqueFolderURL()
            .appendingPathComponent(fileName)

        try fileManager.moveItem(at: url, to: targetURL)

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

#endif
