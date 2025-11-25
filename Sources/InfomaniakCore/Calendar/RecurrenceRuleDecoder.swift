//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

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
