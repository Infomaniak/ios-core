//  RruleDecoder.swift
//  InfomaniakCore
//
//  Created by Baptiste on 25.02.2025.
//

import Foundation

public struct RruleDecoder {
    public let calendar: Calendar
    public var frequency: Frequency?
    public var interval: Int?
    public var end: Int?
    public var count: Int?
    public var byDay: [Weekday]?

    public init(calendar: Calendar = .current, frequency: Frequency?, interval: Int?, end: Int?, count: Int?, byDay: [Weekday]?) {
        self.calendar = calendar
        self.frequency = frequency
        self.interval = interval
        self.end = end
        self.count = count
        self.byDay = byDay
    }
}

// MARK: - ParseStrategy

extension RruleDecoder: ParseStrategy {
    public func parse(_ value: String) throws -> RruleDecoder {
        var parser: RruleDecoder = self
        var countOrUntilSet = 0

        let parts = value.split(separator: ";")

        for part in parts {
            let keyValue = part.split(separator: "=")
            guard keyValue.count == 2 else {
                throw DomainError.invalidKey
            }

            guard let ruleKey = RuleKey(rawValue: String(keyValue[0])) else {
                continue
            }
            let value = String(keyValue[1])

            switch ruleKey {
            case .frequency:
                parser.frequency = try ruleKey.parser.decode(value) as? Frequency
            case .interval:
                parser.interval = try ruleKey.parser.decode(value) as? Int
            case .count:
                parser.count = try ruleKey.parser.decode(value) as? Int
                countOrUntilSet += 1
            case .until:
                parser.end = try ruleKey.parser.decode(value) as? Int
                countOrUntilSet += 1
            case .byDay:
                parser.byDay = try ruleKey.parser.decode(value) as? [Weekday] ?? []
            }
        }

        guard parser.frequency != nil else {
            throw DomainError.missingFrequency
        }

        guard countOrUntilSet < 2 else {
            throw DomainError.bothUntilAndCountSet
        }

        return parser
    }

    private func frequencyNextDate(_ value: String, _ startDate: Date) throws -> Date {
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
}
