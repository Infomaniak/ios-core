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

/// Something that can provide a `Progress` and an async `Result` in order to load an url from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderFileRepresentation: NSObject, ProgressResultable {
    /// Something to transform events to a nice `async Result`
    private let flowToAsync = FlowToAsyncResult<Success>()
    
    /// Shorthand for default FileManager
    private let fileManager = FileManager.default
    
    /// Domain specific errors
    public enum ErrorDomain: Error, Equatable{
        case UTINotFound
        case UnableToLoadFile
    }

    public typealias Success = URL
    public typealias Failure = Error

    public init(from itemProvider: NSItemProvider) throws {
        guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first else {
            throw ErrorDomain.UTINotFound
        }

        // Keep compiler happy
        progress = Progress(totalUnitCount: 1)

        super.init()

        // Set progress and hook completion closure to a combine pipe
        progress = itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [self] fileProviderURL, error in
            guard let fileProviderURL, error == nil else {
                flowToAsync.send(completion: .failure(error ?? ErrorDomain.UnableToLoadFile))
                return
            }

            do {
                let UTI = UTI(rawValue: typeIdentifier as CFString)
                @InjectService var pathProvider: AppGroupPathProvidable
                let temporaryURL = pathProvider.tmpDirectoryURL
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try fileManager.createDirectory(at: temporaryURL, withIntermediateDirectories: true)

                let fileName = fileProviderURL.appendingPathExtension(for: UTI).lastPathComponent
                let temporaryFileURL = temporaryURL.appendingPathComponent(fileName)
                try fileManager.copyItem(atPath: fileProviderURL.path, toPath: temporaryFileURL.path)
                
                flowToAsync.send(temporaryFileURL)
            } catch {
                flowToAsync.send(completion: .failure(error))
            }
        }
    }

    // MARK: ProgressResultable

    public var progress: Progress

    public var result: Result<URL, Error> {
        get async {
            await self.flowToAsync.result
        }
    }
}

#endif
