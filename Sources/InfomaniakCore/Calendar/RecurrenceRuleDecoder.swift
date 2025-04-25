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
public class RecurrenceRuleDecoder {
    public func parse(_ value: String) throws -> RecurrenceRule {
        var ruleCountOrUntilSet = 0
        var frequency: Frequency?
        var interval: Int?
        var lastOccurrence: Int?
        var nbMaxOfOccurrences: Int?
        var daysWithEvents: [Weekday]?
        var nthDayOfMonth: [Int]?

        let parts = value.split(separator: ";")
        for part in parts {
            let keyValue = part.split(separator: "=")
            guard keyValue.count == 2 else {
                throw DomainError.invalidKey
            }

            guard let ruleKey = RuleKey(rawValue: "\(keyValue[0])") else {
                throw DomainError.invalidKey
            }
            let value = "\(keyValue[1])"

            switch ruleKey {
            case .frequency:
                frequency = try ruleKey.parser.decode(value) as? Frequency
            case .interval:
                interval = try ruleKey.parser.decode(value) as? Int
            case .count:
                nbMaxOfOccurrences = try ruleKey.parser.decode(value) as? Int
                ruleCountOrUntilSet += 1
            case .until:
                lastOccurrence = try ruleKey.parser.decode(value) as? Int
                ruleCountOrUntilSet += 1
            case .byDay:
                daysWithEvents = try ruleKey.parser.decode(value) as? [Weekday] ?? []
            case .bySetPos:
                nthDayOfMonth = try ruleKey.parser.decode(value) as? [Int] ?? []
            }
        }

        guard frequency != nil else {
            throw DomainError.missingFrequency
        }

        guard ruleCountOrUntilSet < 2 else {
            throw DomainError.bothUntilAndCountSet
        }

        return RecurrenceRule(
            frequency: frequency,
            interval: interval,
            lastOccurrence: lastOccurrence,
            nbMaxOfOccurrences: nbMaxOfOccurrences,
            daysWithEvents: daysWithEvents,
            nthDayOfMonth: nthDayOfMonth
        )
    }
}
