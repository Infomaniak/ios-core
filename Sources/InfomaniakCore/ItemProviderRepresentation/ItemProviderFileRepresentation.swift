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
        case UTINotFound
        case UnableToLoadFile
    }

    public typealias Success = URL
    public typealias Failure = Error

    /// Init method
    /// - Parameters:
    ///   - itemProvider: The item provider we will be working with
    ///   - preferredImageFileFormat: Specify an output image file format. Supports HEIC and JPG. Will convert only if
    /// itemProvider supports it.
    public init(from itemProvider: NSItemProvider, preferredImageFileFormat: UTI? = nil) throws {
        var typeIdentifiers = itemProvider.registeredTypeIdentifiers
        
        // make sure live photo identifier is at the end of supported formats
        if let matchIndex = typeIdentifiers.index(of: Self.livePhotoIdentifier) {
            typeIdentifiers.remove(at: matchIndex)
            typeIdentifiers.append(Self.livePhotoIdentifier)
        }
        
        guard let typeIdentifier = typeIdentifiers.first else {
            throw ErrorDomain.UTINotFound
        }

        progress = Progress(totalUnitCount: Self.totalSteps)

        super.init()

        // Check if requested an image conversion, and if conversion is available.
        let fileIdentifierToUse = self.preferredImageFileFormat(
            itemProvider: itemProvider,
            typeIdentifier: typeIdentifier,
            preferredImageFileFormat: preferredImageFileFormat
        )

        // Set progress and hook completion closure
        let completionProgress = Progress(totalUnitCount: Self.progressStep)
        progress.addChild(completionProgress, withPendingUnitCount: Self.progressStep)
        
        let loadURLProgress = itemProvider.loadFileRepresentation(forTypeIdentifier: fileIdentifierToUse) { [self] fileProviderURL, error in
            guard let fileProviderURL, error == nil else {
                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendFailure(error ?? ErrorDomain.UnableToLoadFile)
                return
            }

            do {
                let uti = UTI(rawValue: fileIdentifierToUse as CFString)
                @InjectService var pathProvider: AppGroupPathProvidable
                let temporaryURL = try URL.temporaryUniqueFolderURL()

                let fileName = fileProviderURL.appendingPathExtension(for: uti).lastPathComponent
                let temporaryFileURL = temporaryURL.appendingPathComponent(fileName)
                try fileManager.copyItem(atPath: fileProviderURL.path, toPath: temporaryFileURL.path)

                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendSuccess(temporaryFileURL)
            } catch {
                completionProgress.completedUnitCount += Self.progressStep
                flowToAsync.sendFailure(error)
            }
        }
        progress.addChild(loadURLProgress, withPendingUnitCount: Self.progressStep)
    }

    // MARK: ProgressResultable

    public var progress: Progress

    public var result: Result<URL, Error> {
        get async {
            await flowToAsync.result
        }
    }

    // MARK: Private

    /// Check if a File conversion is possible for the provided `itemProvider` and `typeIdentifier`,
    /// returns `typeIdentifier` if no conversion is possible.
    ///
    /// - Parameters:
    ///   - itemProvider: The ItemProvider we work with
    ///   - typeIdentifier: top typeIdentifier for ItemProvider
    ///   - preferredImageFileFormat: The image format the user is requesting
    private func preferredImageFileFormat(itemProvider: NSItemProvider,
                                          typeIdentifier: String,
                                          preferredImageFileFormat: UTI?) -> String {
        if let preferredImageFileFormat = preferredImageFileFormat {
            // Check that itemProvider supports the image types we ask of it
            if itemProvider.hasItemConformingToAnyOfTypeIdentifiers([UTI.heic.identifier, UTI.jpeg.identifier]),
               itemProvider.hasItemConformingToTypeIdentifier(preferredImageFileFormat.identifier) {
                return preferredImageFileFormat.identifier
            }
            // No conversion if not possible
            else {
                return typeIdentifier
            }
        } else {
            // No conversion
            return typeIdentifier
        }
    }
}

#endif
