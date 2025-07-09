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
        case invalidWKST
    }

    public let calendar: Calendar
    public var repetitionFrequency: RepetitionFrequency
    public let lastOccurrence: Date?
    public let nbMaxOfOccurrences: Int?
    public let daysWithEvents: [SpecifiedWeekday]
    public let nthDayOfMonth: [Int]
    public let nthOccurrenceOfMonth: [Int]
    public let firstDayOfWeek: Int

    public init(_ string: String, calendar: Calendar = .current) throws {
        self = try RecurrenceRuleDecoder().parse(string, calendar: calendar)
    }

    public init(
        calendar: Calendar = .current,
        repetitionFrequency: RepetitionFrequency,
        lastOccurrence: Date? = nil,
        nbMaxOfOccurrences: Int? = nil,
        daysWithEvents: [SpecifiedWeekday] = [],
        nthDayOfMonth: [Int] = [],
        nthOccurrenceOfMonth: [Int] = [],
        firstDayOfWeek: Int
    ) {
        var configuredCalendar = calendar
        configuredCalendar.firstWeekday = firstDayOfWeek
        self.calendar = configuredCalendar
        self.repetitionFrequency = repetitionFrequency
        self.lastOccurrence = lastOccurrence
        self.nbMaxOfOccurrences = nbMaxOfOccurrences
        self.daysWithEvents = daysWithEvents
        self.nthDayOfMonth = nthDayOfMonth
        self.nthOccurrenceOfMonth = nthOccurrenceOfMonth
        self.firstDayOfWeek = firstDayOfWeek
    }
}

@available(macOS 15, *)
public extension RecurrenceRule {
    private func getNextWeekDayDate(daysWithEvents: [SpecifiedWeekday],
                                    startDate: Date,
                                    currentDate: Date = Date()) -> Date? {
        guard let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: startDate, to: currentDate).weekOfYear,
              let startOfCurrentWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start else {
            return nil
        }

        if (weeksSinceStart % repetitionFrequency.interval) == 0 {
            let daysThisWeek = daysWithEvents.compactMap { specifiedWeekday -> Date? in
                var components = DateComponents()
                components.weekday = specifiedWeekday.weekday.value
                return calendar.nextDate(
                    after: startOfCurrentWeek,
                    matching: components,
                    matchingPolicy: .nextTimePreservingSmallerComponents
                )
            }.sorted()

            if let nextInWeek = daysThisWeek.first(where: { $0 >= currentDate }) {
                return nextInWeek
            }
        }

        let weeksToAdd = repetitionFrequency.interval - (weeksSinceStart % repetitionFrequency.interval)
        guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: weeksToAdd, to: startOfCurrentWeek)
        else { return nil }

        let daysNextWeek = daysWithEvents.compactMap { specifiedWeekday -> Date? in
            var components = DateComponents()
            components.weekday = specifiedWeekday.weekday.value
            return calendar.nextDate(
                after: nextWeekStart,
                matching: components,
                matchingPolicy: .nextTimePreservingSmallerComponents
            )
        }.sorted()

        return daysNextWeek.first
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
            return handleWeeklyFrequency(startDate: startDate, currentDate: currentDate)

        case .monthly, .yearly:
            return handleComplexFrequency(startDate: startDate, currentDate: currentDate)

        default:
            return nil
        }
    }

    private func handleWeeklyFrequency(startDate: Date, currentDate: Date = Date()) -> Date? {
        guard !daysWithEvents.isEmpty else {
            return calendar.date(byAdding: .weekOfYear, value: repetitionFrequency.interval, to: startDate)
        }

        guard let date = getNextWeekDayDate(daysWithEvents: daysWithEvents, startDate: startDate, currentDate: currentDate) else {
            return nil
        }

        return date
    }

    private func handleComplexFrequency(startDate: Date, currentDate: Date) -> Date? {
        if !daysWithEvents.isEmpty {
            let unit: Calendar.Component = repetitionFrequency.frequency == .monthly ? .month : .year
            let periodsSinceStart = calendar.component(unit, from: currentDate) - calendar.component(unit, from: startDate)

            if (periodsSinceStart % repetitionFrequency.interval) == 0 {
                let nextDateThisPeriod = getNextDateInPeriod(
                    daysWithEvents: daysWithEvents,
                    nthOccurrenceOfMonth: nthOccurrenceOfMonth,
                    startDate: startDate,
                    currentDate: currentDate
                )

                if nextDateThisPeriod != nil {
                    return nextDateThisPeriod
                }
            }

            let unitsToAdd = repetitionFrequency.interval - (periodsSinceStart % repetitionFrequency.interval)
            guard let nextPeriodDate = calendar.date(
                byAdding: unit,
                value: unitsToAdd,
                to: startDate
            ) else { return nil }
            return getNextDateInPeriod(
                daysWithEvents: daysWithEvents,
                nthOccurrenceOfMonth: nthOccurrenceOfMonth,
                startDate: nextPeriodDate,
                currentDate: currentDate
            )
        }

        if !nthDayOfMonth.isEmpty {
            let sortedDaysOfCurrentMonth = getNormalizedDaysOfMonth(days: nthDayOfMonth, currentDate: currentDate)
            let matchingDatesOfCurrentMonth = getMatchingDaysOfMonth(date: startDate, daysOfMonth: sortedDaysOfCurrentMonth)
                .filter { $0 > currentDate }
                .sorted()

            if let nextDateOfMonth = matchingDatesOfCurrentMonth.first {
                return nextDateOfMonth
            }

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
        let sortedDaysOfFirstMonth = getNormalizedDaysOfMonth(days: daysOfMonth, currentDate: startDate)
        let firstMonthComponents = DateComponents(
            year: calendar.component(.year, from: startDate),
            month: calendar.component(.month, from: startDate),
            day: sortedDaysOfFirstMonth.first
        )

        guard let dayInFirstMonth = calendar.date(from: firstMonthComponents), let nextDate = calendar.date(
            byAdding: .month,
            value: repetitionFrequency.interval,
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
        daysWithEvents: [SpecifiedWeekday],
        nthOccurrenceOfMonth: [Int],
        startDate: Date,
        currentDate: Date = Date()
    ) -> Date? {
        let frequency = repetitionFrequency.frequency
        let components: Set<Calendar.Component> = frequency == .monthly ? [.year, .month] : [.year]

        guard let startOfPeriod = calendar.date(from: calendar.dateComponents(components, from: startDate)) else {
            return nil
        }

        if daysWithEvents.contains(where: { $0.position != nil }) {
            let daysWithPosition = daysWithEvents.filter { $0.position != nil }
            var candidates = [Date]()
            for day in daysWithPosition {
                let thisPeriodDates = getPotentialDates(from: startOfPeriod, matching: [day])
                if let pos = day.position,
                   let newDate = calculateNthDays(at: [pos], in: thisPeriodDates).first {
                    candidates.append(newDate)
                }
            }
            if let nextDate = candidates.filter({ $0 > currentDate }).sorted().first {
                return nextDate
            }
        }

        let thisPeriodDates = getPotentialDates(from: startOfPeriod, matching: daysWithEvents)
        if !nthOccurrenceOfMonth.isEmpty {
            let datesThisPeriod = calculateNthDays(at: nthOccurrenceOfMonth, in: thisPeriodDates)
                .filter { $0 > currentDate }
                .sorted()
            if let firstDateThisPeriod = datesThisPeriod.first {
                return firstDateThisPeriod
            }
        }

        if nthOccurrenceOfMonth.isEmpty && !daysWithEvents.contains(where: { $0.position != nil }) {
            if let nextDate = thisPeriodDates.filter({ $0 > currentDate }).sorted().first {
                return nextDate
            }
        }

        return nil
    }

    private func calculateNthDays(at positions: [Int], in dates: [Date]) -> [Date] {
        return positions.compactMap { pos in
            let index = pos >= 0 ? pos - 1 : dates.count + pos
            return dates.indices.contains(index) ? dates[index] : nil
        }
    }

    private func getPotentialDates(
        from startOfPeriod: Date,
        matching weekdays: [SpecifiedWeekday]
    ) -> [Date] {
        let frequency = repetitionFrequency.frequency
        let periodUnit: Calendar.Component = (frequency == .monthly) ? .month : .year

        guard let dayRange = calendar.range(of: .day, in: periodUnit, for: startOfPeriod) else {
            return []
        }

        return dayRange.compactMap { offset -> Date? in
            guard let date = calendar.date(byAdding: .day, value: offset - 1, to: startOfPeriod) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            return weekdays.contains { $0.weekday.value == weekday } ? date : nil
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
