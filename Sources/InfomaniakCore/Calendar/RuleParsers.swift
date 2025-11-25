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

struct FrequencyParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Frequency {
        guard let frequency = Frequency(rawValue: value) else {
            throw RecurrenceRule.ErrorDomain.missingFrequency
        }
        return frequency
    }
}

struct IntervalParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Int {
        guard let intValue = Int(value), intValue > 0 else {
            throw RecurrenceRule.ErrorDomain.invalidInterval
        }
        return intValue
    }
}

struct CountParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Int {
        guard let intValue = Int(value), intValue > 0 else {
            throw RecurrenceRule.ErrorDomain.invalidCount
        }
        return intValue
    }
}

struct UntilParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        guard let formattedDate = formatter.date(from: value) else {
            throw RecurrenceRule.ErrorDomain.invalidUntil
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
                    throw RecurrenceRule.ErrorDomain.invalidByDay
                }
                let specifiedWeekday = SpecifiedWeekday(position: decodedWeekdayPosition, weekday: decodedWeekday)
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
                throw RecurrenceRule.ErrorDomain.invalidByMonthDay
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
                throw RecurrenceRule.ErrorDomain.invalidBySetPos
            }
        }
        return parsedDays
    }
}

struct FirstWeekdayParser: RuleValueDecoder {
    func decode(_ value: String) throws -> Weekday {
        if let day = Weekday(rawValue: value) {
            return day
        } else {
            throw RecurrenceRule.ErrorDomain.invalidWKST
        }
    }
}

protocol RuleValueDecoder {
    associatedtype Output
    func decode(_ value: String) throws -> Output
}
