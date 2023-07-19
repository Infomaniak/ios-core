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

import Foundation

/// Encapsulate a simple asynchronous event and provide a nice swift `async Result<>`.
///
/// Useful when dealing with old xOS APIs that do not work well with swift native structured concurrency.
///
/// The *first* event received will be forwarded. Thread safe.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class FlowToAsyncResult<Success> {
    
    /// Something to deal with live observation
    typealias CompletionClosure = (Result<Success, Error>) -> Void

    // MARK: Private
    
    /// Serial locking queue
    private let lock = DispatchQueue(label: "com.infomaniak.core.FlowToAsyncResult.lock")
    
    /// The internal state of `FlowToAsyncResult`
    private enum State {
        /// Waiting for input events
        case wait
        /// We have a success event
        case success(wrapping: Success)
        /// We have a failure event
        case failure(wrapping: Error)
    }

    /// The state storage
    private var _state: State = .wait

    /// Something to deal with state _before_ observation started
    ///
    /// Thread safe
    private var state: State {
        get {
            lock.sync {
                return _state
            }
        }
        set {
            lock.sync {
                _state = newValue
            }
        }
    }

    /// Something to deal with state _after_ observation started
    private var liveObservation: CompletionClosure?

    /// Starts an observation
    private func observe(_ liveObservation: @escaping CompletionClosure) {
        self.liveObservation = liveObservation
    }

    /// Builds an `async` function to get a `Success`, given internal state.
    private func asyncResult() async throws -> Success {
        switch state {
        case .failure(wrapping: let error):
            /// We have an `error` to send right away
            throw error
        case .success(wrapping: let success):
            /// We have a `Success` type to send right away
            return success
        case .wait:
            // Nothing yet. We start to observe for changes
            return try await withCheckedThrowingContinuation { continuation in
                observe { result in
                    switch result {
                    case .success(let success):
                        continuation.resume(with: .success(success))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: Public

    /// Provides a nice `async Result` public API.
    public var result: Result<Success, Error> {
        get async {
            do {
                let success = try await asyncResult()
                return .success(success)
            } catch {
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
public extension FlowToAsyncResult {
    /// Send a successful event.
    func sendSuccess(_ input: Success) {
        guard case .wait = state else {
            return
        }

        state = .success(wrapping: input)
        liveObservation?(.success(input))
    }

    /// Send an error event.
    func sendFailure(_ error: Error) {
        guard case .wait = state else {
            return
        }

        state = .failure(wrapping: error)
        liveObservation?(.failure(error))
    }
}
