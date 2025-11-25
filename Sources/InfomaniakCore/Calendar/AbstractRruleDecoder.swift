//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

import Foundation

public enum Frequency: String, Sendable {
    case secondly = "SECONDLY"
    case minutely = "MINUTELY"
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

public enum Weekday: String, CaseIterable, Sendable {
    case monday = "MO"
    case tuesday = "TU"
    case wednesday = "WE"
    case thursday = "TH"
    case friday = "FR"
    case saturday = "SA"
    case sunday = "SU"

    var value: Int {
        switch self {
        case .monday:
            return 2
        case .tuesday:
            return 3
        case .wednesday:
            return 4
        case .thursday:
            return 5
        case .friday:
            return 6
        case .saturday:
            return 7
        case .sunday:
            return 1
        }
    }
}

public struct SpecifiedWeekday: Sendable {
    public let position: Int?
    public let weekday: Weekday

    public init(position: Int?, weekday: Weekday) {
        self.position = position
        self.weekday = weekday
    }
}

public enum RuleKey: String, Sendable {
    case frequency = "FREQ"
    case interval = "INTERVAL"
    case count = "COUNT"
    case until = "UNTIL"
    case byDay = "BYDAY"
    case byMonthDay = "BYMONTHDAY"
    case bySetPos = "BYSETPOS"
    case firstWeekday = "WKST"

    var parser: any RuleValueDecoder {
        switch self {
        case .frequency: return FrequencyParser()
        case .interval: return IntervalParser()
        case .count: return CountParser()
        case .until: return UntilParser()
        case .byDay: return ByDayParser()
        case .byMonthDay: return ByMonthDayParser()
        case .bySetPos: return BySetPosParser()
        case .firstWeekday: return FirstWeekdayParser()
        }
    }
}

public struct RepetitionFrequency: Sendable {
    public let frequency: Frequency
    public let interval: Int
    public let firstDayOfWeek: Int

    public init(frequency: Frequency, interval: Int, firstDayOfWeek: Int) {
        self.frequency = frequency
        self.interval = interval
        self.firstDayOfWeek = firstDayOfWeek
    }
}
