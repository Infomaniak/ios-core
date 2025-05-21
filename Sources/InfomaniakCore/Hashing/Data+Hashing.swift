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

extension Digest {
    /// String representation of a `Digest`
    var digestString: String {
        return compactMap { String(format: "%02x", $0) }.joined()
    }
}

/// Hashing data helpers
public extension Data {
    /// Get a `SHA256Digest` of the current Data
    var SHA256Digest: SHA256Digest {
        SHA256.hash(data: self)
    }

    /// Get a `SHA512Digest` of the current Data
    var SHA512Digest: SHA512Digest {
        SHA512.hash(data: self)
    }

    /// Get a `SHA256` String of the current Data
    var SHA256DigestString: String {
        SHA256Digest.digestString
    }

    /// Get a `SHA512` String of the current Data
    var SHA512DigestString: String {
        SHA512Digest.digestString
    }
}
