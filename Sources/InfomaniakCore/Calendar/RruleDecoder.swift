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
public class RruleDecoder {
    public func parse(_ value: String) throws -> Rrule {
        var countOrUntilSet = 0
        var frequency: Frequency?
        var interval: Int?
        var end: Int?
        var count: Int?
        var byDay: [Weekday]?
        var bySetPos: [Int]?

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
                count = try ruleKey.parser.decode(value) as? Int
                countOrUntilSet += 1
            case .until:
                end = try ruleKey.parser.decode(value) as? Int
                countOrUntilSet += 1
            case .byDay:
                byDay = try ruleKey.parser.decode(value) as? [Weekday] ?? []
            case .bySetPos:
                bySetPos = try ruleKey.parser.decode(value) as? [Int] ?? []
            }
        }

        guard frequency != nil else {
            throw DomainError.missingFrequency
        }

        guard countOrUntilSet < 2 else {
            throw DomainError.bothUntilAndCountSet
        }

        return Rrule(frequency: frequency, interval: interval, end: end, count: count, byDay: byDay, bySetPos: bySetPos)
    }
}
