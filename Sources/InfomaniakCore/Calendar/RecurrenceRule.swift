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

@available(macOS 12, *)
public struct RecurrenceRule {
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

    public let calendar: Calendar
    public let frequency: Frequency?
    public let interval: Int?
    public let lastOccurrence: Int?
    public let nbMaxOfOccurrences: Int?
    public let daysWithEvents: [Weekday]?
    public let nthDayOfMonth: [Int]?

    init(_ string: String) throws {
        self = try RecurrenceRuleDecoder().parse(string)
    }

    public init(
        calendar: Calendar = .current,
        frequency: Frequency? = nil,
        interval: Int? = nil,
        lastOccurrence: Int? = nil,
        nbMaxOfOccurrences: Int? = nil,
        daysWithEvents: [Weekday]? = nil,
        nthDayOfMonth: [Int]? = nil
    ) {
        self.calendar = calendar
        self.frequency = frequency
        self.interval = interval
        self.lastOccurrence = lastOccurrence
        self.nbMaxOfOccurrences = nbMaxOfOccurrences
        self.daysWithEvents = daysWithEvents
        self.nthDayOfMonth = nthDayOfMonth
    }
}

@available(macOS 12, *)
public extension RecurrenceRule {
    private func daysBetweenCurrentDateAndClosestEventDay(_ currentDate: Date) -> Int {
        let startingDayDigit = Int(currentDate.formatted(Date.FormatStyle().weekday(.oneDigit))) ?? 0
        var allOccupiedDays: [Int] = []

        guard let daysWithEvents else {
            return -1
        }

        for dayWithEvents in daysWithEvents {
            if let day = Weekday.allCases.firstIndex(of: dayWithEvents) {
                allOccupiedDays.append(day + 1)
            }
        }

        let closestPastDay: Int
        if let closest = allOccupiedDays.filter({ $0 <= startingDayDigit }).max() {
            closestPastDay = closest
        } else {
            closestPastDay = allOccupiedDays.max() ?? -1
        }

        let closestFutureDay: Int
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
            return calendar.weekdaySymbols.count
        } else {
            return (calendar.weekdaySymbols.count - closestPastDay) + closestFutureDay
        }
    }

    private func frequencyNextDate(_ startDate: Date, _ currentDate: Date? = nil) throws -> Date {
        let parsedValue = self

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
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
            if parsedValue.daysWithEvents != nil {
                interval = daysBetweenCurrentDateAndClosestEventDay(startDate)
                component = .day
            } else {
                component = .weekOfYear
            }
        case .monthly:
            if let daysWithEvents = parsedValue.daysWithEvents {
                if daysWithEvents.count > 1 {
                    interval = daysBetweenCurrentDateAndClosestEventDay(startDate)
                    component = .day
                } else {
                    return getMonthlyNextDate(
                        daysWithEvents: daysWithEvents,
                        nthDayOfMonth: parsedValue.nthDayOfMonth?[0] ?? 1,
                        startDate: startDate,
                        calendar: calendar,
                        currentDate
                    )
                }
            } else {
                component = .month
            }
        case .yearly:
            if parsedValue.daysWithEvents != nil {
                interval = daysBetweenCurrentDateAndClosestEventDay(startDate)
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

    private func getMonthlyNextDate(
        daysWithEvents: [Weekday],
        nthDayOfMonth: Int,
        startDate: Date,
        calendar: Calendar,
        _ currentDate: Date? = nil
    ) -> Date {
        let components = calendar.dateComponents([.year, .month], from: startDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return startDate }
        guard let firstDayOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) else { return startDate }

        let potentialDates = getPotentialDatesOfMonth(startDate, firstDayOfMonth, daysWithEvents)
        let potentialDatesNextMonth = getPotentialDatesOfMonth(startDate, firstDayOfNextMonth, daysWithEvents)

        if nthDayOfMonth > 0, nthDayOfMonth <= potentialDates.count {
            if currentDate ?? Date() < potentialDates[nthDayOfMonth - 1] {
                return potentialDates[nthDayOfMonth - 1]
            } else {
                return potentialDatesNextMonth[nthDayOfMonth - 1]
            }
        } else if nthDayOfMonth < 0, abs(nthDayOfMonth) <= potentialDates.count {
            if currentDate ?? Date() < potentialDates[potentialDates.count + nthDayOfMonth] {
                return potentialDates[potentialDates.count + nthDayOfMonth]
            } else {
                return potentialDatesNextMonth[potentialDates.count + nthDayOfMonth]
            }
        }

        return startDate
    }

    private func getPotentialDatesOfMonth(_ startDate: Date, _ firstDayOfMonth: Date, _ daysWithEvents: [Weekday]) -> [Date] {
        var potentialDates = [Date]()
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else { return [] }

        for dayOffset in daysInMonth {
            if let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                guard let weekday = Int(currentDate.formatted(Date.FormatStyle().weekday(.oneDigit))) else {
                    return []
                }

                if daysWithEvents.contains(where: { $0.rawValue == Weekday.allCases[weekday - 1].rawValue }) {
                    potentialDates.append(currentDate)
                }
            }
        }
        return potentialDates
    }

    func allNextOccurrences(_ startDate: Date, _ currentDate: Date? = nil) throws -> [Date] {
        let parsedValue = self
        var result: [Date] = [startDate]
        var newDate: Date = startDate

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let nbMaxOfOccurrences = parsedValue.nbMaxOfOccurrences {
            result = allNextOccurrencesWithCountRule(nbMaxOfOccurrences, startDate, currentDate)
        }

        if let lastOccurrence = parsedValue.lastOccurrence {
            result = allNextOccurrencesWithEndRule(lastOccurrence, startDate, currentDate)
        }

        guard result.count < 2 else { return result }

        while result.last ?? startDate < currentDate ?? Date() {
            if let nextDate = try? frequencyNextDate(newDate, currentDate) {
                result.append(nextDate)
                newDate = nextDate
            } else {
                return result
            }
        }
        return result
    }

    private func allNextOccurrencesWithCountRule(_ nbMaxOfOccurrences: Int, _ startDate: Date,
                                                 _ currentDate: Date? = nil) -> [Date] {
        var result: [Date] = [startDate]
        var newDate: Date = startDate

        for _ in 0 ..< nbMaxOfOccurrences - 1 {
            if let nextDate = try? frequencyNextDate(newDate, currentDate) {
                result.append(nextDate)
                newDate = nextDate
            }
        }
        return result
    }

    private func allNextOccurrencesWithEndRule(_ lastOccurrence: Int, _ startDate: Date, _ currentDate: Date? = nil) -> [Date] {
        var result: [Date] = [startDate]
        var newDate: Date = startDate

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let endDate = formatter.date(from: String(lastOccurrence)) {
            while result.last ?? endDate < endDate {
                if let nextDate = try? frequencyNextDate(newDate, currentDate) {
                    if nextDate <= endDate {
                        result.append(nextDate)
                        newDate = nextDate
                    } else {
                        break
                    }
                }
            }
        }
        return result
    }

    func getNextOccurrence(_ startDate: Date, _ currentDate: Date = Date()) throws -> Date? {
        let parsedValue = self
        let allDates: [Date] = try allNextOccurrences(startDate, currentDate)
        guard let nearestPassedDate = getNearestPassedDate(currentDate, allDates) else {
            return nil
        }

        let nextDate = try frequencyNextDate(nearestPassedDate, currentDate)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let lastOccurrence = parsedValue.lastOccurrence, let endDate = formatter.date(from: String(lastOccurrence)),
           endDate <= nextDate {
            return nil
        }

        return nextDate
    }

    private func getNearestPassedDate(_ targetDate: Date, _ dates: [Date]) -> Date? {
        for date in dates.reversed() {
            if let nextDate = try? frequencyNextDate(date),
               date <= targetDate && targetDate <= nextDate {
                return date
            }
        }
        return nil
    }
}
