/*
 Infomaniak Core - iOS
 Copyright (C) 2025 Infomaniak Network SA

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

@available(macOS 12, *)
public struct Rrule {
    public let calendar: Calendar
    public var frequency: Frequency?
    public var interval: Int?
    public var end: Int?
    public var count: Int?
    public var byDay: [Weekday]?
    public var bySetPos: [Int]?

    init(_ string: String) throws {
        self = try RruleDecoder().parse(string)
    }

    public init(
        calendar: Calendar = .current,
        frequency: Frequency? = nil,
        interval: Int? = nil,
        end: Int? = nil,
        count: Int? = nil,
        byDay: [Weekday]? = nil,
        bySetPos: [Int]? = nil
    ) {
        self.calendar = calendar
        self.frequency = frequency
        self.interval = interval
        self.end = end
        self.count = count
        self.byDay = byDay
        self.bySetPos = bySetPos
    }
}
