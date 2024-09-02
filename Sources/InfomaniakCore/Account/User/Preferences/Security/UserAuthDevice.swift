/*
 Infomaniak Core - iOS
 Copyright (C) 2022 Infomaniak Network SA

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

@frozen public struct UserAuthDevice: Codable, Hashable {
    public let id: Int
    public let name: Int
    public let lastConnexion: Date
    public let userAgent: String
    public let userIp: String
    public let device: String
    /// Date User auth device has been created
    public let createdAt: Date
    /// Date User auth device has been updated
    public let updatedAt: Date
    /// Date User auth device has been deleted
    public let deletedAt: Date
}
