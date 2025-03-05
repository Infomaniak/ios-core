//  RuleParsers.swift
//  InfomaniakCore
//
//  Created by Baptiste on 05.03.2025.
//

import Foundation

public enum DomainError: Error {
    case invalidInterval
    case invalidKey
    case invalidCount
    case invalidUntil
    case invalidByDay
    case missingFrequency
    case bothUntilAndCountSet
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
