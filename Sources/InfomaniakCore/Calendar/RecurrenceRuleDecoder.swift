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

public class RecurrenceRuleDecoder {
    public init() {}

    public func parse(_ value: String, calendar: Calendar = .current) throws -> RecurrenceRule {
        var ruleCountOrUntilSet = 0
        var frequency: Frequency?
        var interval: Int?
        var lastOccurrence: Date?
        var maxOccurrences: Int?
        var daysWithEvents: [SpecifiedWeekday]?
        var nthDayOfMonth: [Int]?
        var nthOccurrenceOfMonth: [Int]?
        var firstDayOfWeek: Weekday?

        let parts = value.split(separator: ";")
        for part in parts {
            let keyValue = part.split(separator: "=")
            guard keyValue.count == 2 else {
                throw RecurrenceRule.ErrorDomain.invalidKey
            }

            guard let ruleKey = RuleKey(rawValue: "\(keyValue[0])") else {
                throw RecurrenceRule.ErrorDomain.invalidKey
            }
            let value = "\(keyValue[1])"

            switch ruleKey {
            case .frequency:
                frequency = try ruleKey.parser.decode(value) as? Frequency
            case .interval:
                interval = try ruleKey.parser.decode(value) as? Int
            case .count:
                maxOccurrences = try ruleKey.parser.decode(value) as? Int
                ruleCountOrUntilSet += 1
            case .until:
                lastOccurrence = try ruleKey.parser.decode(value) as? Date
                ruleCountOrUntilSet += 1
            case .byDay:
                daysWithEvents = try ruleKey.parser.decode(value) as? [SpecifiedWeekday] ?? []
            case .byMonthDay:
                nthDayOfMonth = try ruleKey.parser.decode(value) as? [Int] ?? []
            case .bySetPos:
                nthOccurrenceOfMonth = try ruleKey.parser.decode(value) as? [Int] ?? []
            case .firstWeekday:
                firstDayOfWeek = try ruleKey.parser.decode(value) as? Weekday ?? .monday
            }
        }

        guard let frequency else {
            throw RecurrenceRule.ErrorDomain.missingFrequency
        }

        guard ruleCountOrUntilSet < 2 else {
            throw RecurrenceRule.ErrorDomain.bothUntilAndCountSet
        }

        return RecurrenceRule(
            calendar: calendar,
            repetitionFrequency: RepetitionFrequency(
                frequency: frequency,
                interval: interval ?? 1,
                firstDayOfWeek: firstDayOfWeek?.value ?? Weekday.monday.value
            ),
            lastOccurrence: lastOccurrence,
            maxOccurrences: maxOccurrences,
            daysWithEvents: daysWithEvents ?? [],
            nthDayOfMonth: nthDayOfMonth ?? [],
            nthOccurrenceOfMonth: nthOccurrenceOfMonth ?? []
        )
    }
}
