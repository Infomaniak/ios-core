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

public struct UserPhone: Codable {
    public var id: Int
    public var phone: String
    public var createdAt: Date?
    public var reminder: Bool
    public var checked: Bool
    public var type: String

    private enum CodingKeys: String, CodingKey {
        case id
        case phone
        case createdAt = "created_at"
        case reminder
        case checked
        case type
    }
}
