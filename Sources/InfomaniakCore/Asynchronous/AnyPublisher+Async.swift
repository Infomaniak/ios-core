/*
 Infomaniak Core - iOS
 Copyright (C) 2021 Infomaniak Network SA

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

public enum AnyPublisherError: Error, Equatable {
    case emptySteamError
}

/// Extending AnyPublisher for async await
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AnyPublisher {
    /// Bridge `AnyPublisher` to `Result<>`
    /// - Returns: a `Result<>` wrapping the state of this `AnyPublisher`
    var result: Result<Output, Error> {
        get async {
            do {
                let result = try await asyncCall()
                return .success(result)
            } catch {
                return .failure(error)
            }
        }
    }

    /// Bridge `AnyPublisher` to async await
    /// - Returns: the first() Output of this AnyPublisher
    func asyncCall() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = first()
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                }, receiveValue: { value in
                    continuation.resume(with: .success(value))
                })
        }
    }
}
