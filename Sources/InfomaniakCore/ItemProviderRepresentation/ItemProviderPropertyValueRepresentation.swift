/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

/// Something that can provide a `Progress` and an async `Result`
/// from a `NSItemProvider` that is conforming to propertyList UTI
///
/// Returns arbitrary Dictionary
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderPropertyValueRepresentation: NSObject, ProgressResultable {
    /// Progress increment size
    private static let progressStep: Int64 = 1

    /// Number of steps to complete the task
    private static let totalSteps: Int64 = 1

    /// Something to transform events to a nice `async Result`
    private let flowToAsync = FlowToAsyncResult<Success>()

    private let itemProvider: NSItemProvider

    /// Domain specific errors
    public enum ErrorDomain: Error, Equatable {
        /// loadItem cast failed
        case unableToReadDictionary
    }

    public typealias Success = NSDictionary
    public typealias Failure = Error

    public init(from itemProvider: NSItemProvider) {
        progress = Progress(totalUnitCount: Self.totalSteps)

        self.itemProvider = itemProvider
        super.init()

        Task {
            let completionProgress = Progress(totalUnitCount: Self.totalSteps)
            progress.addChild(completionProgress, withPendingUnitCount: Self.progressStep)

            defer {
                completionProgress.completedUnitCount += Self.progressStep
            }

            let propertyListIdentifier = UTI.propertyList.identifier
            if self.itemProvider.hasItemConformingToTypeIdentifier(propertyListIdentifier) {
                guard let resultDictionary = try await self.itemProvider
                    .loadItem(forTypeIdentifier: propertyListIdentifier) as? NSDictionary else {
                    flowToAsync.sendFailure(ErrorDomain.unableToReadDictionary)
                    return
                }

                flowToAsync.sendSuccess(resultDictionary)

            } else {
                flowToAsync.sendFailure(ErrorDomain.unableToReadDictionary)
            }
        }
    }

    // MARK: ProgressResultable

    public var progress: Progress

    public var result: Result<Success, Failure> {
        get async {
            return await flowToAsync.result
        }
    }
}
