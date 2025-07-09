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

struct FrequencyParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Frequency {
        guard let frequency = Frequency(rawValue: value) else {
            throw RecurrenceRule.DomainError.missingFrequency
        }
        return frequency
    }
}

struct IntervalParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Int {
        guard let intValue = Int(value), intValue > 0 else {
            throw RecurrenceRule.DomainError.invalidInterval
        }
        return intValue
    }
}

struct CountParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Int {
        guard let intValue = Int(value), intValue > 0 else {
            throw RecurrenceRule.DomainError.invalidCount
        }
        return intValue
    }
}

struct UntilParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        guard let formattedDate = formatter.date(from: value) else {
            throw RecurrenceRule.DomainError.invalidUntil
        }

        return formattedDate
    }
}

struct ByDayParser: RuleValueDecoder {
    func decode(_ value: String) throws -> [SpecifiedWeekday] {
        let allDays = Weekday.allCases.map { $0.rawValue }.joined(separator: "|")
        let regex = try NSRegularExpression(pattern: "([+-]?\\d+)?(\(allDays))")
        let weekdays = value.split(separator: ",").map { String($0) }
        var parsedWeekdays: [SpecifiedWeekday] = []

        for weekday in weekdays {
            let range = NSRange(weekday.startIndex..., in: weekday)
            if let match = regex.firstMatch(in: weekday, options: [], range: range) {
                let decodedWeekdayPosition: Int?
                let decodedWeekday: Weekday
                if let positionRange = Range(match.range(at: 1), in: weekday),
                   let position = Int(String(weekday[positionRange])) {
                    decodedWeekdayPosition = position
                } else {
                    decodedWeekdayPosition = nil
                }
                if let dayRange = Range(match.range(at: 2), in: weekday), let day = Weekday(rawValue: String(weekday[dayRange])) {
                    decodedWeekday = day
                } else {
                    throw RecurrenceRule.DomainError.invalidByDay
                }
                let specifiedWeekday = SpecifiedWeekday(weekday: decodedWeekday, position: decodedWeekdayPosition)
                parsedWeekdays.append(specifiedWeekday)
            }
        }

        return parsedWeekdays
    }
}

struct ByMonthDayParser: RuleValueDecoder {
    func decode(_ value: String) throws -> [Int] {
        let days = value.split(separator: ",").map { String($0) }
        var parsedDays: [Int] = []

        for day in days {
            if let intValue = Int(day) {
                parsedDays.append(intValue)
            } else {
                throw RecurrenceRule.DomainError.invalidByMonthDay
            }
        }
        return parsedDays
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
                throw RecurrenceRule.DomainError.invalidBySetPos
            }
        }
        return parsedDays
    }
}

struct WkstParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Weekday {
        if let day = Weekday(rawValue: value) {
            return day
        } else {
            throw RecurrenceRule.DomainError.invalidWKST
        }
    }
}

protocol RuleValueDecoder {
    associatedtype Output
    func decode(_ value: String) throws -> Output
}
