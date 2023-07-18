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
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class FlowToAsyncResult<Success> {
    // MARK: Private

    /// Internal observation of the Combine progress Pipe
    private var flowObserver: AnyCancellable?

    /// Internal Task that wraps the combine result observation
    private lazy var resultTask: Task<Success, Error> = Task {
        let result: Success = try await withCheckedThrowingContinuation { continuation in
            self.flowObserver = flow.sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                self.flowObserver?.cancel()
            } receiveValue: { value in
                continuation.resume(with: .success(value))
            }
        }

        return result
    }

    // MARK: Public

    /// Track task progress with internal Combine pipe.
    ///
    /// Public entry point, send result threw this pipe.
    public let flow = PassthroughSubject<Success, Error>()

    /// Provides a nice `async Result` public API
    public var result: Result<Success, Error> {
        get async {
            return await resultTask.result
        }
    }

    // MARK: Init

    public init() {
        // META keep SonarCloud happy
    }
}

/// Shorthand to access underlying flow
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension FlowToAsyncResult {
    func send(_ input: Success) {
        flow.send(input)
    }

    func send(completion: Subscribers.Completion<Error>) {
        flow.send(completion: completion)
    }
}
