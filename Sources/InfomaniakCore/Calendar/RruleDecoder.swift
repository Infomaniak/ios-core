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

    public init(
        calendar: Calendar = .current,
        frequency: Frequency? = nil,
        interval: Int? = nil,
        end: Int? = nil,
        count: Int? = nil,
        byDay: [Weekday]? = nil
    ) {
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
        var parser = RruleDecoder()
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

    private func daysBetween(_ parsedValue: RruleDecoder, _ currentDate: Date) -> Int {
        let startingDayDigit = Int(currentDate.formatted(Date.FormatStyle().weekday(.oneDigit))) ?? 0
        var allOccupiedDays: [Int] = []
        let closestPastDay: Int
        let closestFutureDay: Int
        for i in 0 ..< (parsedValue.byDay?.count ?? 0) {
            if let day = Weekday.allCases.firstIndex(of: parsedValue.byDay![i]) {
                allOccupiedDays.append(day + 1)
            }
        }
        if let closest = allOccupiedDays.filter({ $0 <= startingDayDigit }).max() {
            closestPastDay = closest
        } else {
            closestPastDay = allOccupiedDays.max() ?? -1
        }

        if let closest = allOccupiedDays.filter({ $0 > startingDayDigit }).min() {
            closestFutureDay = closest
        } else {
            closestFutureDay = allOccupiedDays.min() ?? -1
        }

        guard closestPastDay != -1, closestFutureDay != -1 else {
            return -1
        }

        if closestFutureDay >= closestPastDay {
            return closestFutureDay - closestPastDay
        } else {
            return (7 - closestPastDay) + closestFutureDay
        }
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
            if parsedValue.byDay != nil {
                let daysGap = daysBetween(parsedValue, startDate)
                newDate = calendar.date(byAdding: .day, value: daysGap, to: startDate) ?? startDate
            } else {
                newDate = calendar.date(byAdding: .weekOfYear, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
            }
        case .monthly:
            if parsedValue.byDay != nil {
                let daysGap = daysBetween(parsedValue, startDate)
                newDate = calendar.date(byAdding: .day, value: daysGap, to: startDate) ?? startDate
            } else {
                newDate = calendar.date(byAdding: .month, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
            }
        case .yearly:
            if parsedValue.byDay != nil {
                let daysGap = daysBetween(parsedValue, startDate)
                newDate = calendar.date(byAdding: .day, value: daysGap, to: startDate) ?? startDate
            } else {
                newDate = calendar.date(byAdding: .year, value: parsedValue.interval ?? 1, to: startDate) ?? startDate
            }
        default:
            break
        }

        return newDate
    }

    public func allNextOccurrences(_ value: String, _ startDate: Date, _ currentDate: Date? = nil) throws -> [Date] {
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
        while result.last ?? startDate < currentDate ?? Date() {
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
        let allDates: [Date] = try allNextOccurrences(value, startDate, currentDate)
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
