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

@available(iOS 11, macOS 12, *)
public class RruleDecoder {
    public func parse(_ value: String) throws -> Rrule {
        var countOrUntilSet = 0
        var rule = Rrule()
        let parts = value.split(separator: ";")

        for part in parts {
            let keyValue = part.split(separator: "=")
            guard keyValue.count == 2 else {
                throw DomainError.invalidKey
            }

            guard let ruleKey = RuleKey(rawValue: "\(keyValue[0])") else {
                continue
            }
            let value = "\(keyValue[1])"

            switch ruleKey {
            case .frequency:
                rule.frequency = try ruleKey.parser.decode(value) as? Frequency
            case .interval:
                rule.interval = try ruleKey.parser.decode(value) as? Int
            case .count:
                rule.count = try ruleKey.parser.decode(value) as? Int
                countOrUntilSet += 1
            case .until:
                rule.end = try ruleKey.parser.decode(value) as? Int
                countOrUntilSet += 1
            case .byDay:
                rule.byDay = try ruleKey.parser.decode(value) as? [Weekday] ?? []
            case .bySetPos:
                rule.bySetPos = try ruleKey.parser.decode(value) as? [Int] ?? []
            }
        }

        guard rule.frequency != nil else {
            throw DomainError.missingFrequency
        }

        guard countOrUntilSet < 2 else {
            throw DomainError.bothUntilAndCountSet
        }

        return rule
    }
}

// MARK: - ParseStrategy

@available(iOS 11, macOS 12, *)
extension RruleDecoder {
    private func daysBetween(_ parsedValue: Rrule, _ currentDate: Date) -> Int {
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
        let parsedValue = try Rrule(value)

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var newDate = startDate
        var interval = parsedValue.interval ?? 1
        var component: Calendar.Component = .day

        switch parsedValue.frequency {
        case .minutely:
            component = .minute
        case .hourly:
            component = .hour
        case .daily:
            component = .day
        case .weekly:
            if parsedValue.byDay != nil {
                interval = daysBetween(parsedValue, startDate)
                component = .day
            } else {
                component = .weekOfYear
            }
        case .monthly:
            if let byDay = parsedValue.byDay {
                if byDay.count > 1 {
                    interval = daysBetween(parsedValue, startDate)
                    component = .day
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
                    return newDate
                }

            } else {
                component = .month
            }
        case .yearly:
            if parsedValue.byDay != nil {
                interval = daysBetween(parsedValue, startDate)
                component = .day
            } else {
                component = .year
            }
        default:
            break
        }

        guard let newDate = calendar.date(byAdding: component, value: interval, to: startDate) else {
            return startDate
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
        let parsedValue = try Rrule(value)
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
        let parsedValue = try Rrule(value)
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
