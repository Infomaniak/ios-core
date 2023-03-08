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

import CryptoKit
import Foundation

/// Hashing String helpers
@available(iOS 13.0, *)
public extension String {
    
    /// Get a `SHA256Digest` of the current String
    var SHA256Digest: SHA256Digest {
        SHA256.hash(data: self.data(using: .utf8) ?? Data())
    }

    /// Get a `SHA512Digest` of the current String
    var SHA512Digest: SHA512Digest {
        SHA512.hash(data: self.data(using: .utf8) ?? Data())
    }

    /// Get a `SHA256` String of the current String
    var SHA256DigestString: String {
        self.SHA256Digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Get a `SHA512` String of the current String
    var SHA512DigestString: String {
        self.SHA512Digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
