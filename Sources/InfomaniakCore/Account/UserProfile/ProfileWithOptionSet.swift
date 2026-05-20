/*
 Infomaniak Core - iOS
 Copyright (C) 2026 Infomaniak Network SA

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

public struct ProfileWithOptionSet: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let emails = ProfileWithOptionSet(rawValue: 1 << 0)
    public static let phones = ProfileWithOptionSet(rawValue: 1 << 1)
    public static let security = ProfileWithOptionSet(rawValue: 1 << 2)

    public static let all: ProfileWithOptionSet = [.emails, .phones, .security]

    public var queryValue: String {
        var values: [String] = []
        if contains(.emails) { values.append("emails") }
        if contains(.phones) { values.append("phones") }
        if contains(.security) { values.append("security") }
        return values.joined(separator: ",")
    }

    public var queryItem: URLQueryItem? {
        guard !queryValue.isEmpty else { return nil }

        return URLQueryItem(name: "with", value: queryValue)
    }
}
