/*
 Infomaniak kDrive - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import Combine
import Foundation

/// Encapsulate a simple asynchronous event into a Combine flow in order to provide a nice swift `async Result<>`.
///
/// Useful when dealing with old xOS APIs that do not work well with swift native structured concurrency.
///
/// You _must_ await the result before sending events by convention.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class FlowToAsyncResult<Success> {
    /// Track progress with an internal Combine PassthroughSubject
    private let flow = PassthroughSubject<Success, Error>()

    // MARK: Public

    /// Provides a nice `async Result` public API.
    ///
    /// You are expected to `await result` before sending events by convention.
    public var result: Result<Success, Error> {
        get async {
            do {
                let result = try await flow.eraseToAnyPublisher().async()
                return .success(result)
            }
            catch {
                return .failure(error)
            }
        }
    }

    // MARK: Init

    public init() {
        // META keep SonarCloud happy
    }
}

/// Event handling
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension FlowToAsyncResult {
    
    /// Send an event. You must await the result first by convention.
    func send(_ input: Success) {
        flow.send(input)
        flow.send(completion: .finished)
    }

    /// Send a completion. You must await the result first by convention.
    func send(completion: Subscribers.Completion<Error>) {
        flow.send(completion: completion)
    }
}
