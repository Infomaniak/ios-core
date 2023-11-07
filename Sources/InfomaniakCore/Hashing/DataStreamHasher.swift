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

// @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
// extension Digest: DigestStringRepresentable {}

/// Hashing String helpers
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class DataStreamHasher {
    /// The internal state of the stream hasher
    var state = StreamState.begin

    enum StreamState {
        case begin
        case progress(received: Int)
        case done(digest: any Digest)
    }

    /// the hasher
    var sha: SHA256

    public init() {
        state = .begin
        sha = SHA256()
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

        sha.update(data: data)
    }

    @discardableResult
    public func finalize() -> (any Digest) {
        if case .done(let digest) = state {
            return digest
        }

        let digest = sha.finalize()
        state = .done(digest: digest)
        return digest
    }

    public var digestString: String? {
        guard case .done(let digest) = state else {
            return nil
        }

        return digest.digestString
    }

    public var digest: (any Digest)? {
        guard case .done(let digest) = state else {
            return nil
        }

        return digest
    }
}
