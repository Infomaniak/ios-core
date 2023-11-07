/*
 Infomaniak Core - iOS
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

import CryptoKit
import Foundation

/// Hashing a Stream of Data.
///
/// Not thread safe, use within the same queue / actor.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class StreamHasher<Hasher: HashFunction> {
    /// The internal state of the stream hasher
    var state = StreamState.begin

    /// Enum to represent the state of the stream hasher
    enum StreamState {
        case begin
        case progress(received: Int)
        case done(digest: Hasher.Digest)
    }

    /// internal hasher
    var hasher: Hasher

    public init() {
        state = .begin
        hasher = Hasher()
    }

    /// Returns true until finalize() is called
    private var isNotDone: Bool {
        switch state {
        case .begin, .progress:
            true
        case .done:
            false
        }
    }

    /// Process the next batch of arbitrary data from a stream
    /// - Parameter data: data of arbitrary length
    public func update(_ data: Data) {
        guard isNotDone else {
            return
        }

        let offset: Int
        if case .progress(let value) = state {
            offset = value + data.count
        } else {
            offset = data.count
        }

        state = .progress(received: offset)

        hasher.update(data: data)
    }

    /// Call this to compute the final digest
    ///
    /// You cannot call update() anymore, create a new instance instead.
    @discardableResult
    public func finalize() -> Hasher.Digest {
        if case .done(let digest) = state {
            return digest
        }

        let digest = hasher.finalize()
        state = .done(digest: digest)
        return digest
    }

    // MARK: Access to digest result

    public var digestString: String? {
        guard case .done(let digest) = state else {
            return nil
        }

        return digest.digestString
    }

    public var digest: Hasher.Digest? {
        guard case .done(let digest) = state else {
            return nil
        }

        return digest
    }
}
