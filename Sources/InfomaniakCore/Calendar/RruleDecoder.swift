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
    public var bySetPos: [Int]?

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
            case .bySetPos:
                parser.bySetPos = try ruleKey.parser.decode(value) as? [Int] ?? []
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

        if closestFutureDay > closestPastDay {
            return closestFutureDay - closestPastDay
        } else if closestFutureDay == closestPastDay {
            return 7
        } else {
            return (7 - closestPastDay) + closestFutureDay
        }
    }

    private func frequencyNextDate(_ value: String, _ startDate: Date, _ currentDate: Date? = nil) throws -> Date {
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
            if let byDay = parsedValue.byDay {
                if byDay.count > 1 {
                    let daysGap = daysBetween(parsedValue, startDate)
                    newDate = calendar.date(byAdding: .day, value: daysGap, to: startDate) ?? startDate
                } else {
                    if let bySetPos = parsedValue.bySetPos {
                        newDate = getDateForBySetPos(
                            byDay: byDay,
                            bySetPos: bySetPos[0],
                            startDate: startDate,
                            calendar: calendar,
                            currentDate
                        )
                    } else {
                        newDate = getDateForBySetPos(
                            byDay: byDay,
                            bySetPos: 1,
                            startDate: startDate,
                            calendar: calendar,
                            currentDate
                        )
                    }
                }

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

    private func getDateForBySetPos(
        byDay: [Weekday],
        bySetPos: Int,
        startDate: Date,
        calendar: Calendar,
        _ currentDate: Date? = nil
    ) -> Date {
        let components = calendar.dateComponents([.year, .month], from: startDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return startDate }
        guard let firstDayofNextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) else { return startDate }

        var potentialDates: [Date] = []
        var potentialDatesNextMonth: [Date] = []

        for dayOffset in 0 ..< 31 {
            if let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                guard let weekday = Int(currentDate.formatted(Date.FormatStyle().weekday(.oneDigit))) else {
                    return startDate
                }

                if byDay.contains(where: { $0.rawValue == Weekday.allCases[weekday - 1].rawValue }) {
                    potentialDates.append(currentDate)
                }
            }

            if let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: firstDayofNextMonth) {
                guard let weekday = Int(currentDate.formatted(Date.FormatStyle().weekday(.oneDigit))) else {
                    return startDate
                }

                if byDay.contains(where: { $0.rawValue == Weekday.allCases[weekday - 1].rawValue }) {
                    potentialDatesNextMonth.append(currentDate)
                }
            }
        }

        if bySetPos > 0, bySetPos <= potentialDates.count {
            if currentDate ?? Date() < potentialDates[bySetPos - 1] {
                return potentialDates[bySetPos - 1]
            } else {
                return potentialDatesNextMonth[bySetPos - 1]
            }
        } else if bySetPos < 0, abs(bySetPos) <= potentialDates.count {
            if currentDate ?? Date() < potentialDates[potentialDates.count + bySetPos] {
                return potentialDates[potentialDates.count + bySetPos]
            } else {
                return potentialDatesNextMonth[potentialDates.count + bySetPos]
            }
        }

        return startDate
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
                if let nextDate = try? frequencyNextDate(value, newDate, currentDate) {
                    result.append(nextDate)
                    newDate = nextDate
                }
            }
            return result
        }

        if let end = parsedValue.end {
            if let endDate = formatter.date(from: String(end)) {
                while result.last ?? startDate < endDate {
                    if let nextDate = try? frequencyNextDate(value, newDate, currentDate) {
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
            if let nextDate = try? frequencyNextDate(value, newDate, currentDate) {
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

        let nextDate = try frequencyNextDate(value, nearestPassedDate, currentDate)

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
