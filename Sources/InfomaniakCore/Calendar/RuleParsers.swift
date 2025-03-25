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

public enum DomainError: Error {
    case invalidInterval
    case invalidKey
    case invalidCount
    case invalidUntil
    case invalidByDay
    case missingFrequency
    case bothUntilAndCountSet
    case invaliBySetPos
}

struct FrequencyParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Frequency? {
        return isFrequencyValid(value) ? Frequency(rawValue: value) : nil
    }
}

struct IntervalParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Int {
        guard let intValue = Int(value), intValue > 0 else {
            throw DomainError.invalidInterval
        }
        return intValue
    }
}

struct CountParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Int {
        guard let intValue = Int(value), intValue > 0 else {
            throw DomainError.invalidCount
        }
        return intValue
    }
}

struct UntilParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Int {
        guard let intValue = Int(value), isValidDate(intValue) else {
            throw DomainError.invalidUntil
        }
        return intValue
    }
}

struct ByDayParser: RuleValueDecoder {
    func decode(_ value: String) throws -> [Weekday] {
        let weekdays = value.split(separator: ",").map { String($0) }
        var parsedWeekdays: [Weekday] = []

        for weekday in weekdays {
            if let wkday = Weekday(rawValue: weekday), isValidWeekday(wkday.rawValue) {
                parsedWeekdays.append(wkday)
            } else {
                throw DomainError.invalidByDay
            }
        }

        return parsedWeekdays
    }
}

struct BySetPosParser: RuleValueDecoder {
    func decode(_ value: String) throws -> [Int] {
        let days = value.split(separator: ",").map { String($0) }
        var parsedDays: [Int] = []

        for day in days {
            if let intValue = Int(day) {
                parsedDays.append(intValue)
            } else {
                throw DomainError.invaliBySetPos
            }
        }
        return parsedDays
    }
}

private func isFrequencyValid(_ value: String) -> Bool {
    switch value {
    case "SECONDLY", "MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY":
        return true
    default:
        return false
    }
}

private func isValidDate(_ value: Int) -> Bool {
    let stringVal = String(value)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    if formatter.date(from: stringVal) != nil {
        return true
    }
    return false
}

private func isValidWeekday(_ day: String) -> Bool {
    switch day {
    case "MO", "TU", "WE", "TH", "FR", "SA", "SU":
        return true
    default:
        return false
    }
}
