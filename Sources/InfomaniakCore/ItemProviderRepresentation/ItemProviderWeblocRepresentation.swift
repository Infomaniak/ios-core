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

/// Something that can provide a `Progress` and an async `Result` in order to make a webloc plist from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderWeblocRepresentation: NSObject, ProgressResultable {
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
        // Keep compiler happy
        progress = Progress(totalUnitCount: 1)

        super.init()

        progress = itemProvider.loadObject(ofClass: URL.self) { [self] path, error in
            guard error == nil, let path: URL = path else {
                let error: Error = error ?? ErrorDomain.unableToLoadURLForObject
                flowToAsync.sendFailure(error)
                return
            }

            // Save the URL as a webloc file (plist)
            let content = ["URL": path.absoluteString]

            do {
                @InjectService var pathProvider: AppGroupPathProvidable
                let tmpDirectoryURL = pathProvider.tmpDirectoryURL
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try fileManager.createDirectory(at: tmpDirectoryURL, withIntermediateDirectories: true)

                let fileName = path.lastPathComponent
                let targetURL = tmpDirectoryURL.appendingPathComponent("\(fileName).webloc")
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(content)
                try data.write(to: targetURL)

                flowToAsync.sendSuccess(targetURL)
            } catch {
                flowToAsync.sendFailure(error)
            }
        }
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
