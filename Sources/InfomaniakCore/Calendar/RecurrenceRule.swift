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

public struct RecurrenceRule {
    public enum DomainError: Error {
        case invalidInterval
        case invalidKey
        case invalidCount
        case invalidUntil
        case invalidByDay
        case missingFrequency
        case bothUntilAndCountSet
        case invalidBySetPos
    }

    public let calendar: Calendar
    public var repetitionFrequency: RepetitionFrequency
    public let lastOccurrence: Date?
    public let nbMaxOfOccurrences: Int?
    public let daysWithEvents: [Weekday]
    public let nthDayOfMonth: [Int]

    init(_ string: String, calendar: Calendar = .current) throws {
        self = try RecurrenceRuleDecoder().parse(string, calendar: calendar)
    }

    public init(
        calendar: Calendar = .current,
        repetitionFrequency: RepetitionFrequency,
        lastOccurrence: Date? = nil,
        nbMaxOfOccurrences: Int? = nil,
        daysWithEvents: [Weekday] = [],
        nthDayOfMonth: [Int] = []
    ) {
        self.calendar = calendar
        self.repetitionFrequency = repetitionFrequency
        self.lastOccurrence = lastOccurrence
        self.nbMaxOfOccurrences = nbMaxOfOccurrences
        self.daysWithEvents = daysWithEvents
        self.nthDayOfMonth = nthDayOfMonth
    }
}

@available(macOS 15, *)
public extension RecurrenceRule {
    private func computeDaysBetween(_ date: Date) -> Int? {
        let allOccupiedDays = daysWithEvents.map { $0.value }

        let dateDay = calendar.component(.weekday, from: date)

        let differences = allOccupiedDays.map { $0 - dateDay }

        let pastDayDifference = differences.filter { $0 <= 0 }.max()
        let nextDayDifference = differences.filter { $0 > 0 }.min()

        guard let pastDayDifference, let nextDayDifference,
              let pastDate = calendar.date(byAdding: .day, value: pastDayDifference, to: date),
              let nextDate = calendar.date(byAdding: .day, value: nextDayDifference, to: date) else {
            return nil
        }

        return calendar.dateComponents([.day], from: pastDate, to: nextDate).day
    }

    @available(macOS 15, *)
    private func frequencyNextDate(_ startDate: Date, _ currentDate: Date = Date()) throws -> Date? {
        let frequency = repetitionFrequency.frequency
        let interval = repetitionFrequency.interval

        switch frequency {
        case .minutely:
            return calendar.date(byAdding: .minute, value: interval, to: startDate)

        case .hourly:
            return calendar.date(byAdding: .hour, value: interval, to: startDate)

        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: startDate)

        case .weekly:
            return handleWeeklyFrequency(startDate: startDate)

        case .monthly, .yearly:
            return handleComplexFrequency(startDate: startDate, currentDate: currentDate, frequency: frequency)

        default:
            return nil
        }
    }

    private func handleWeeklyFrequency(startDate: Date) -> Date? {
        guard !daysWithEvents.isEmpty else {
            return calendar.date(byAdding: .weekOfYear, value: repetitionFrequency.interval, to: startDate)
        }

        guard let daysBetween = computeDaysBetween(startDate) else {
            return nil
        }

        return calendar.date(byAdding: .day, value: daysBetween, to: startDate)
    }

    @available(macOS 15, *)
    private func handleComplexFrequency(startDate: Date, currentDate: Date, frequency: Frequency) -> Date? {
        let interval = repetitionFrequency.interval

        if !daysWithEvents.isEmpty {
            if frequency == .monthly && daysWithEvents.count <= 1 {
                return getNextDateInPeriod(
                    frequency: frequency,
                    daysWithEvents: daysWithEvents,
                    nthDayOfMonth: nthDayOfMonth,
                    startDate: startDate,
                    currentDate: currentDate
                )
            } else {
                let interval = computeDaysBetween(startDate) ?? 1
                return calendar.date(byAdding: .day, value: interval, to: startDate)
            }
        }

        return calendar.date(byAdding: frequency == .monthly ? .month : .year, value: interval, to: startDate)
    }

    private func getNextDateInPeriod(
        frequency: Frequency,
        daysWithEvents: [Weekday],
        nthDayOfMonth: [Int],
        startDate: Date,
        currentDate: Date = Date()
    ) -> Date? {
        let unit: Calendar.Component = frequency == .monthly ? .month : .year

        guard let startOfPeriod = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate)),
              let startOfNextPeriod = calendar.date(byAdding: unit, value: 1, to: startOfPeriod) else {
            return nil
        }

        let thisPeriodDates = getPotentialDates(from: startOfPeriod, frequency: frequency, matching: daysWithEvents)
        let nextPeriodDates = getPotentialDates(from: startOfNextPeriod, frequency: frequency, matching: daysWithEvents)

        let datesThisPeriod = calculateNthDays(at: nthDayOfMonth, in: thisPeriodDates)
            .filter { $0 > currentDate }
            .sorted()

        if let firstDateThisPeriod = datesThisPeriod.first {
            return firstDateThisPeriod
        }

        let datesNextPeriod = calculateNthDays(at: nthDayOfMonth, in: nextPeriodDates)
            .sorted()

        return datesNextPeriod.first
    }

    private func calculateNthDays(at positions: [Int], in dates: [Date]) -> [Date] {
        return positions.compactMap { pos in
            let index = pos >= 0 ? pos - 1 : dates.count + pos
            return dates.indices.contains(index) ? dates[index] : nil
        }
    }

    @available(macOS 15, *)
    private func getPotentialDates(
        from startOfPeriod: Date,
        frequency: Frequency,
        matching weekdays: [Weekday]
    ) -> [Date] {
        let rangeUnit: Calendar.Component = (frequency == .monthly) ? .day : .dayOfYear
        let periodUnit: Calendar.Component = (frequency == .monthly) ? .month : .year

        guard let dayRange = calendar.range(of: rangeUnit, in: periodUnit, for: startOfPeriod) else {
            return []
        }

        return dayRange.compactMap { offset -> Date? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfPeriod) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            return weekdays.contains { $0.value == weekday } ? date : nil
        }
    }

    func allNextOccurrences(_ startDate: Date, _ currentDate: Date = Date()) throws -> [Date] {
        if let nbMaxOfOccurrences {
            return allNextOccurrencesWithCountRule(nbMaxOfOccurrences, startDate, currentDate)
        }

        if let lastOccurrence {
            return allNextOccurrencesWithEndRule(lastOccurrence, startDate, currentDate)
        }

        var result = [startDate]
        while result.last ?? startDate < currentDate {
            if let newDate = result.last, let nextDate = try? frequencyNextDate(newDate, currentDate) {
                result.append(nextDate)
            } else {
                return result
            }
        }
        return result
    }

    private func allNextOccurrencesWithCountRule(_ nbMaxOfOccurrences: Int,
                                                 _ startDate: Date,
                                                 _ currentDate: Date = Date()) -> [Date] {
        var result = [startDate]

        for _ in 0 ..< nbMaxOfOccurrences - 1 {
            if let newDate = result.last, let nextDate = try? frequencyNextDate(newDate, currentDate) {
                result.append(nextDate)
            }
        }
        return result
    }

    private func allNextOccurrencesWithEndRule(_ lastOccurrence: Date,
                                               _ startDate: Date,
                                               _ currentDate: Date = Date()) -> [Date] {
        var result = [startDate]

        while result.last ?? lastOccurrence < lastOccurrence {
            if let newDate = result.last, let nextDate = try? frequencyNextDate(newDate, currentDate) {
                if nextDate <= lastOccurrence {
                    result.append(nextDate)
                } else {
                    break
                }
            }
        }
        return result
    }

    func getNextOccurrence(_ startDate: Date, _ currentDate: Date = Date()) throws -> Date? {
        let allDates = try allNextOccurrences(startDate, currentDate)
        guard let nearestPassedDate = getNearestPassedDate(currentDate, allDates) else {
            return nil
        }

        guard let nextDate = try frequencyNextDate(nearestPassedDate, currentDate) else {
            return nil
        }

        if let lastOccurrence, lastOccurrence <= nextDate {
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
