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

public struct UserAuthDevice: Codable {
    public var id: Int
    public var name: String
    public var lastConnexion: Date
    public var userAgent: String
    public var userIp: String
    public var device: String
    /// Date User auth device has been created
    public var createdAt: Date
    /// Date User auth device has been updated
    public var updatedAt: Date
    /// Date User auth device has been deleted
    public var deletedAt: Date
}
