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

public enum Frequency: String {
    case secondly = "SECONDLY"
    case minutely = "MINUTELY"
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

public enum Weekday: String, CaseIterable {
    case monday = "MO"
    case tuesday = "TU"
    case wednesday = "WE"
    case thursday = "TH"
    case friday = "FR"
    case saturday = "SA"
    case sunday = "SU"
}

@available(macOS 12, *)
public enum RuleKey: String {
    case frequency = "FREQ"
    case interval = "INTERVAL"
    case count = "COUNT"
    case until = "UNTIL"
    case byDay = "BYDAY"
    case bySetPos = "BYSETPOS"

    var parser: any RuleValueDecoder {
        switch self {
        case .frequency: return FrequencyParser()
        case .interval: return IntervalParser()
        case .count: return CountParser()
        case .until: return UntilParser()
        case .byDay: return ByDayParser()
        case .bySetPos: return BySetPosParser()
        }
    }
}
