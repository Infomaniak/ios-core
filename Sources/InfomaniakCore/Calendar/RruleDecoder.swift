//
//  RruleDecoder.swift
//  InfomaniakCore
//
//  Created by Baptiste on 25.02.2025.
//

import Foundation

public struct RruleDecoder: Sendable {
    public enum Frequency: String, CaseIterable, Codable, Sendable {
        case secondly = "SECONDLY"
        case minutely = "MINUTELY"
        case hourly = "HOURLY"
        case daily = "DAILY"
        case weekly = "WEEKLY"
        case monthly = "MONTHLY"
        case yearly = "YEARLY"
    }

    public enum Weekday: String, CaseIterable, Codable, Sendable {
        case monday = "MO"
        case tuesday = "TU"
        case wednesday = "WE"
        case thursday = "TH"
        case friday = "FR"
        case saturday = "SA"
        case sunday = "SU"
    }

    public enum rule: String, CaseIterable, Codable {
        case frequency = "FREQ"
        case interval = "INTERVAL"
        case count = "COUNT"
        case until = "UNTIL"
        case byDay = "BYDAY"
    }

    public let frequency: Frequency
    public let calendar: Calendar
    public let interval: Int?
    public let end: Int?
    public let count: Int?
    public let byDay: [Weekday]?

    public init(frequency: Frequency, interval: Int?, calendar: Calendar = .current, end: Int?, count: Int?, byDay: [Weekday]?) {
        self.frequency = frequency
        self.interval = interval
        self.calendar = calendar
        self.end = end
        self.count = count
        self.byDay = byDay
    }
}

// MARK: - ParseStrategy

extension RruleDecoder: ParseStrategy {
    public enum DomainError: Error {
        case invalidInterval
        case invalidKey
        case invalidCount
        case invalidUntil
        case invalidByDay
        case missingFrequency
        case bothUntilAndCountSet
    }

    public func parse(_ value: String) throws -> RruleDecoder {
        var frequency: Frequency?
        var interval: Int?
        var count: Int?
        var end: Int?
        var countOrUntilSet = 0
        var byDay: [RruleDecoder.Weekday] = []

        let parts = value.split(separator: ";")

        for part in parts {
            let keyValue = part.split(separator: "=")
            guard keyValue.count == 2 else {
                throw DomainError.invalidKey
            }

            let key = keyValue[0]
            let val = String(keyValue[1])

            switch key {
            case rule.frequency.rawValue:
                if isFrequencyValid(val) {
                    frequency = RruleDecoder.Frequency(rawValue: val)
                }
            case rule.interval.rawValue:
                if let intValue = Int(val), intValue > 0 {
                    interval = intValue
                } else {
                    throw DomainError.invalidInterval
                }
            case rule.count.rawValue:
                if let intValue = Int(val), intValue > 0 {
                    count = intValue
                    countOrUntilSet += 1
                } else {
                    throw DomainError.invalidCount
                }
            case rule.until.rawValue:
                if let intValue = Int(val), isValidDate(intValue) {
                    end = intValue
                    countOrUntilSet += 1
                } else {
                    throw DomainError.invalidUntil
                }
            case rule.byDay.rawValue:
                let weekdays = val.split(separator: ",")
                for weekday in weekdays {
                    if let wkday = RruleDecoder.Weekday(rawValue: String(weekday)) {
                        if isValidWeekday(wkday.rawValue) {
                            byDay.append(wkday)
                        }
                    } else {
                        throw DomainError.invalidByDay
                    }
                }
            default:
                continue
            }
        }

        guard let freq = frequency else {
            throw DomainError.missingFrequency
        }

        if countOrUntilSet > 1 {
            throw DomainError.bothUntilAndCountSet
        }

        return RruleDecoder(frequency: freq, interval: interval, calendar: calendar, end: end, count: count, byDay: byDay)
    }

    public func frequencyNextDate(_ value: String, _ startDate: Date) throws -> Date {
        let parsedValue = try parse(value)

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var newDate = startDate

        switch parsedValue.frequency {
        case .minutely:
            newDate = calendar.date(byAdding: .minute, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
        case .hourly:
            newDate = calendar.date(byAdding: .hour, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
        case .daily:
            newDate = calendar.date(byAdding: .day, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
        case .weekly:
            newDate = calendar.date(byAdding: .weekOfYear, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
        case .monthly:
            newDate = calendar.date(byAdding: .month, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
        case .yearly:
            newDate = calendar.date(byAdding: .year, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
        default:
            break
        }

        return newDate
    }

    public func allNextOccurrences(_ value: String, _ startDate: Date) throws -> [Date] {
        let parsedValue = try parse(value)
        var result: [Date] = [startDate]
        var newDate: Date = startDate

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let count = parsedValue.count {
            for _ in 0 ..< count - 1 {
                if let nextDate = try? frequencyNextDate(value, newDate) {
                    result.append(nextDate)
                    newDate = nextDate
                }
            }
            return result
        }

        if let end = parsedValue.end {
            if let endDate = formatter.date(from: String(end)) {
                while result.last ?? startDate < endDate {
                    if let nextDate = try? frequencyNextDate(value, newDate) {
                        if nextDate <= endDate {
                            result.append(nextDate)
                            newDate = nextDate
                        } else {
                            return result
                        }
                    }
                }
            }
        }
        while result.last ?? startDate < Date() {
            if let nextDate = try? frequencyNextDate(value, newDate) {
                result.append(nextDate)
                newDate = nextDate
            } else {
                return result
            }
        }
        return result
    }

    public func getNextOccurrence(_ value: String, _ startDate: Date, _ currentDate: Date = Date()) throws -> Date? {
        let parsedValue = try parse(value)
        let allDates: [Date] = try allNextOccurrences(value, startDate)
        guard let nearestPassedDate = getNearestPassedDate(currentDate, allDates, value) else {
            return nil
        }

        let nextDate = try frequencyNextDate(value, nearestPassedDate)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let end = parsedValue.end {
            if let endDate = formatter.date(from: String(end)), endDate <= nextDate {
                return nil
            }
        }

        return nextDate
    }

    private func getNearestPassedDate(_ targetDate: Date, _ dates: [Date], _ value: String) -> Date? {
        for date in dates.reversed() {
            if let nextDate = try? frequencyNextDate(value, date) {
                if date <= targetDate && targetDate <= nextDate {
                    return date
                }
            }
        }
        return nil
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
        guard let _: Date = formatter.date(from: stringVal) else {
            return false
        }

        return true
    }

    private func isValidWeekday(_ day: String) -> Bool {
        switch day {
        case "MO", "TU", "WE", "TH", "FR", "SA", "SU":
            return true
        default:
            return false
        }
    }
}
