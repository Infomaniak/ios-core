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

import Foundation

/// LZFSE Wrapper
public extension Data {
    /// Compressed data using a zstd like algorithm: lzfse
    func compressed() -> Self? {
        guard let data = try? (self as NSData).compressed(using: .lzfse) as Data else {
            return nil
        }
        return data
    }

    /// Decompressed data from a lzfse buffer
    func decompressed() -> Self? {
        guard let data = try? (self as NSData).decompressed(using: .lzfse) as Data else {
            return nil
        }
        return data
    }

    // MARK: - String helpers

    /// Decompressed string from a lzfse buffer
    func decompressedString() -> String? {
        guard let decompressedData = decompressed() else {
            return nil
        }
        let string = String(decoding: decompressedData, as: UTF8.self)
        return string
    }
}
