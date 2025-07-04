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
        case invalidByMonthDay
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
    public let nthOccurenceOfMonth: [Int]

    public init(_ string: String, calendar: Calendar = .current) throws {
        self = try RecurrenceRuleDecoder().parse(string, calendar: calendar)
    }

    public init(
        calendar: Calendar = .current,
        repetitionFrequency: RepetitionFrequency,
        lastOccurrence: Date? = nil,
        nbMaxOfOccurrences: Int? = nil,
        daysWithEvents: [Weekday] = [],
        nthDayOfMonth: [Int] = [],
        nthOccurenceOfMonth: [Int] = []
    ) {
        self.calendar = calendar
        self.repetitionFrequency = repetitionFrequency
        self.lastOccurrence = lastOccurrence
        self.nbMaxOfOccurrences = nbMaxOfOccurrences
        self.daysWithEvents = daysWithEvents
        self.nthDayOfMonth = nthDayOfMonth
        self.nthOccurenceOfMonth = nthOccurenceOfMonth
    }
}

@available(macOS 15, *)
public extension RecurrenceRule {
    private func daysBetweenPreviousAndNextEvent(date: Date) -> Int? {
        let allOccupiedDays = daysWithEvents.map { $0.value }
        let dateDay = calendar.component(.weekday, from: date)
        let daysInWeek = calendar.maximumRange(of: .weekday)?.count ?? 7

        let differences = allOccupiedDays.map { $0 - dateDay }

        let pastDayDifference = differences.filter { $0 <= 0 }.max()
        let nextDayDifference = differences
            .map { ($0 + daysInWeek) % daysInWeek }
            .filter { $0 > 0 }.min()

        guard let pastDayDifference, let nextDayDifference,
              let pastDate = calendar.date(byAdding: .day, value: pastDayDifference, to: date),
              let nextDate = calendar.date(byAdding: .day, value: nextDayDifference, to: date) else {
            return nil
        }

        return calendar.dateComponents([.day], from: pastDate, to: nextDate).day
    }

    private func frequencyNextDate(startDate: Date, currentDate: Date) throws -> Date? {
        let interval = repetitionFrequency.interval

        switch repetitionFrequency.frequency {
        case .minutely:
            return calendar.date(byAdding: .minute, value: interval, to: startDate)

        case .hourly:
            return calendar.date(byAdding: .hour, value: interval, to: startDate)

        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: startDate)

        case .weekly:
            return handleWeeklyFrequency(startDate: startDate)

        case .monthly, .yearly:
            return handleComplexFrequency(startDate: startDate, currentDate: currentDate)

        default:
            return nil
        }
    }

    private func handleWeeklyFrequency(startDate: Date) -> Date? {
        guard !daysWithEvents.isEmpty else {
            return calendar.date(byAdding: .weekOfYear, value: repetitionFrequency.interval, to: startDate)
        }

        guard let daysBetween = daysBetweenPreviousAndNextEvent(date: startDate) else {
            return nil
        }

        return calendar.date(byAdding: .day, value: daysBetween, to: startDate)
    }

    private func handleComplexFrequency(startDate: Date, currentDate: Date) -> Date? {
        if !daysWithEvents.isEmpty {
            return getNextDateInPeriod(
                daysWithEvents: daysWithEvents,
                nthOccurenceOfMonth: nthOccurenceOfMonth,
                startDate: startDate,
                currentDate: currentDate
            )
        }

        if !nthDayOfMonth.isEmpty {
            return getNextMonthDayDate(startDate: startDate, daysOfMonth: nthDayOfMonth, currentDate: currentDate)
        }

        return calendar.date(
            byAdding: repetitionFrequency.frequency == .monthly ? .month : .year,
            value: repetitionFrequency.interval,
            to: startDate
        )
    }

    private func getNormalizedDaysOfMonth(days: [Int], currentDate: Date = Date()) -> [Int] {
        var dayList: [Int] = []
        for day in days {
            if day < 0 {
                guard let range = calendar.range(of: .day, in: .month, for: currentDate) else { continue }
                let negativeDay = range.upperBound + day
                dayList.append(negativeDay)
            } else {
                dayList.append(day)
            }
        }
        return dayList.sorted()
    }

    private func getNextMonthDayDate(
        startDate: Date,
        daysOfMonth: [Int],
        currentDate: Date = Date()
    ) -> Date? {
        if startDate > currentDate {
            return startDate
        }

        let interval = repetitionFrequency.interval
        let sortedDaysOfCurrentMonth = getNormalizedDaysOfMonth(days: daysOfMonth, currentDate: currentDate)
        let matchingDatesOfCurrentMonth = getMatchingDaysOfMonth(date: startDate, daysOfMonth: sortedDaysOfCurrentMonth)
            .filter { $0 > currentDate }
            .sorted()

        if let nextDateOfMonth = matchingDatesOfCurrentMonth.first {
            return nextDateOfMonth
        }

        let sortedDaysOfFirstMonth = getNormalizedDaysOfMonth(days: daysOfMonth, currentDate: startDate)
        let firstMonthComponents = DateComponents(
            year: calendar.component(.year, from: startDate),
            month: calendar.component(.month, from: startDate),
            day: sortedDaysOfFirstMonth.first
        )

        guard let dayInFirstMonth = calendar.date(from: firstMonthComponents), let nextDate = calendar.date(
            byAdding: .month,
            value: interval,
            to: dayInFirstMonth
        ) else { return nil }

        return nextDate
    }

    private func getMatchingDaysOfMonth(date: Date, daysOfMonth: [Int]) -> [Date] {
        var dates: [Date] = []
        for day in daysOfMonth {
            let components = DateComponents(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date),
                day: day
            )
            if let date = calendar.date(from: components) {
                dates.append(date)
            }
        }
        return dates
    }

    private func getNextDateInPeriod(
        daysWithEvents: [Weekday],
        nthOccurenceOfMonth: [Int],
        startDate: Date,
        currentDate: Date = Date()
    ) -> Date? {
        let frequency = repetitionFrequency.frequency
        let unit: Calendar.Component = frequency == .monthly ? .month : .year
        let components: Set<Calendar.Component> = frequency == .monthly ? [.year, .month] : [.year]

        guard let startOfPeriod = calendar.date(from: calendar.dateComponents(components, from: startDate)),
              let startOfNextPeriod = calendar.date(byAdding: unit, value: 1, to: startOfPeriod) else {
            return nil
        }

        let thisPeriodDates = getPotentialDates(from: startOfPeriod, matching: daysWithEvents)
        let nextPeriodDates = getPotentialDates(from: startOfNextPeriod, matching: daysWithEvents)

        let datesThisPeriod = calculateNthDays(at: nthOccurenceOfMonth, in: thisPeriodDates)
            .filter { $0 > currentDate }
            .sorted()

        if let firstDateThisPeriod = datesThisPeriod.first {
            return firstDateThisPeriod
        }

        let datesNextPeriod = calculateNthDays(at: nthOccurenceOfMonth, in: nextPeriodDates)
            .sorted()

        return datesNextPeriod.first
    }

    private func calculateNthDays(at positions: [Int], in dates: [Date]) -> [Date] {
        return positions.compactMap { pos in
            let index = pos >= 0 ? pos - 1 : dates.count + pos
            return dates.indices.contains(index) ? dates[index] : nil
        }
    }

    private func getPotentialDates(
        from startOfPeriod: Date,
        matching weekdays: [Weekday]
    ) -> [Date] {
        let frequency = repetitionFrequency.frequency
        let periodUnit: Calendar.Component = (frequency == .monthly) ? .month : .year

        guard let dayRange = calendar.range(of: .day, in: periodUnit, for: startOfPeriod) else {
            return []
        }

        return dayRange.compactMap { offset -> Date? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfPeriod) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            return weekdays.contains { $0.value == weekday } ? date : nil
        }
    }

    func allOccurrencesSinceStartDate(_ startDate: Date, _ currentDate: Date = Date()) throws -> [Date] {
        if let nbMaxOfOccurrences {
            return allNextOccurrencesWithCountRule(
                nbMaxOfOccurrences: nbMaxOfOccurrences,
                startDate: startDate,
                currentDate: currentDate
            )
        }

        if let lastOccurrence {
            return allNextOccurrencesWithEndRule(lastOccurrence: lastOccurrence, startDate: startDate, currentDate: currentDate)
        }

        var result = [startDate]
        guard let lastDate = try? frequencyNextDate(startDate: currentDate, currentDate: currentDate) else {
            return result
        }
        while result.last ?? startDate < lastDate {
            if let newDate = result.last, let nextDate = try? frequencyNextDate(startDate: newDate, currentDate: currentDate) {
                result.append(nextDate)
            } else {
                return result
            }
        }
        return result
    }

    private func allNextOccurrencesWithCountRule(nbMaxOfOccurrences: Int,
                                                 startDate: Date,
                                                 currentDate: Date = Date()) -> [Date] {
        var result = [startDate]

        for _ in 0 ..< nbMaxOfOccurrences - 1 {
            if let newDate = result.last, let nextDate = try? frequencyNextDate(startDate: newDate, currentDate: currentDate) {
                result.append(nextDate)
            }
        }
        return result
    }

    private func allNextOccurrencesWithEndRule(lastOccurrence: Date,
                                               startDate: Date,
                                               currentDate: Date = Date()) -> [Date] {
        var result = [startDate]

        while result.last ?? lastOccurrence < lastOccurrence {
            if let newDate = result.last, let nextDate = try? frequencyNextDate(startDate: newDate, currentDate: currentDate) {
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
        let allDates = try allOccurrencesSinceStartDate(startDate, currentDate)
        guard let nearestPastDate = getNearestPastDate(targetDate: currentDate, dates: allDates) else {
            return startDate
        }

        guard let nextDate = try frequencyNextDate(startDate: nearestPastDate, currentDate: currentDate) else {
            return nil
        }

        if let lastOccurrence, lastOccurrence <= nextDate {
            return nil
        }

        guard let lastDate = allDates.last, nextDate <= lastDate else {
            return allDates.last
        }

        return nextDate
    }

    private func getNearestPastDate(targetDate: Date, dates: [Date]) -> Date? {
        for date in dates.reversed() {
            if let nextDate = try? frequencyNextDate(startDate: date, currentDate: targetDate),
               date <= targetDate && targetDate <= nextDate {
                return date
            }
        }
        return nil
    }
}
