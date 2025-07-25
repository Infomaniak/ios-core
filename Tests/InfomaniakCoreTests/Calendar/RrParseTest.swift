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
@testable import InfomaniakCore
import Testing

@Suite("RecurrenceRuleDecoderTests")
struct RecurrenceRuleDecoderTests {
    let calendar: Calendar
    let parser: RecurrenceRuleDecoder

    init() {
        let calendar = Calendar(identifier: .gregorian)

        self.calendar = calendar
        parser = RecurrenceRuleDecoder()
    }

    @Test("Throws an error for invalid KEY Rule Part", arguments: [
        "INTERVAL=", "COUNT=", "UNTIL="
    ])
    func throwsErrorForInvalidKeyRulePart(invalidInterval: String) throws {
        let rfcString = "FREQ=DAILY;\(invalidInterval)"
        #expect(throws: RecurrenceRule.DomainError.invalidKey) {
            try parser.parse(rfcString)
        }
    }

    @Test("Parse FREQ Rule Part", arguments: zip(
        ["MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY"],
        [Frequency.minutely, .hourly, .daily, .weekly, .monthly, .yearly]
    ))
    func parseFrequencyRulePart(rfcFrequency: String, expected: Frequency) throws {
        let rfcString = "FREQ=\(rfcFrequency)"
        let result = try parser.parse(rfcString)

        #expect(result.repetitionFrequency.frequency == expected)
    }

    @Test("Throws an error for invalid FREQ Rule Part")
    func returnsNilForInvalidFrequencyRulePart() throws {
        #expect(throws: RecurrenceRule.DomainError.missingFrequency) {
            try parser.parse("FREQ=FOOBAR")
        }
    }

    @Test("Parse INTERVAL Rule Part", arguments: zip(["INTERVAL=1", "INTERVAL=2", "INTERVAL=10"], [1, 2, 10]))
    func parseIntervalRulePart(rfcInterval: String, expected: Int) throws {
        let rfcString = "FREQ=DAILY;\(rfcInterval)"
        let result = try parser.parse(rfcString)

        #expect(result.repetitionFrequency.interval == expected)
    }

    @Test("Throws an error for invalid INTERVAL Rule Part", arguments: [
        "INTERVAL=-1", "INTERVAL=0", "INTERVAL=foo"
    ])
    func throwsErrorForInvalidIntervalRulePart(invalidInterval: String) throws {
        let rfcString = "FREQ=DAILY;\(invalidInterval)"
        #expect(throws: RecurrenceRule.DomainError.invalidInterval) {
            try parser.parse(rfcString)
        }
    }

    @Test("Parses COUNT as a specific occurrence limit", arguments: zip(["COUNT=1", "COUNT=5"], [1, 5]))
    func parseCountRulePart(rfcCount: String, expected: Int) throws {
        let rfcString = "FREQ=DAILY;\(rfcCount)"
        let result = try parser.parse(rfcString)

        #expect(result.nbMaxOfOccurrences == expected)
    }

    @Test("Throws an error for invalid COUNT Rule Part", arguments: ["COUNT=-2", "COUNT=1- ", "COUNT=foobar"])
    func throwsErrorForInvalidCountRulePart(invalidCount: String) throws {
        let rfcString = "FREQ=DAILY;\(invalidCount)"
        #expect(throws: RecurrenceRule.DomainError.invalidCount) {
            try parser.parse(rfcString)
        }
    }

    @Test("Parse UNTIL DATE Rule Part")
    func parseUntilDateRulePart() throws {
        let rfcString = "FREQ=DAILY;UNTIL=20250111"
        let expected = Date(timeIntervalSince1970: 1_736_550_000)
        let res = try parser.parse(rfcString, calendar: calendar)

        guard let result = res.lastOccurrence else {
            return
        }

        #expect(result.timeIntervalSince1970 == expected.timeIntervalSince1970)
    }

    @Test("Throws an error for invalid UNTIL Rule Part", arguments: ["UNTIL=20251350", "UNTIL=foobar", "UNTIL=1"])
    func throwsErrorForInvalidUntilRulePart(invalidString: String) throws {
        let rfcString = "FREQ=DAILY;\(invalidString)"
        #expect(throws: RecurrenceRule.DomainError.invalidUntil) {
            try parser.parse(rfcString)
        }
    }

    @Test("Throws an error when both UNTIL and COUNT are specified")
    func throwsErrorWhenBothUntilAndCountAreSpecified() throws {
        let rfcString = "FREQ=DAILY;UNTIL=21000101;COUNT=1"
        #expect(throws: RecurrenceRule.DomainError.bothUntilAndCountSet) {
            try parser.parse(rfcString)
        }
    }

    @Test(
        "Parse BYDAY every weekday Rule Part",
        arguments: zip(
            ["BYDAY=MO", "BYDAY=TU", "BYDAY=WE", "BYDAY=TH", "BYDAY=FR"],
            [Weekday.monday, .tuesday, .wednesday, .thursday, .friday]
        )
    )
    func parseByDayEveryWeekdayRulePart(rfcByDay: String, expected: Weekday) throws {
        let rfcString = "FREQ=DAILY;\(rfcByDay)"
        let result = try parser.parse(rfcString)

        #expect(result.daysWithEvents == [expected])
    }

    @Test("Parse BYDAY with multiple weekdays Rule Part")
    func parseByDayEveryWeekdayRulePart() throws {
        let rfcString = "FREQ=DAILY;BYDAY=MO,TH"
        let result = try parser.parse(rfcString)

        #expect(result.daysWithEvents == [.monday, .thursday])
    }

    @Test("Parse BYSETPOS Rule Part")
    func parseBySetPosRulePart() throws {
        let rfcString = "FREQ=MONTHLY;BYSETPOS=2,5,10,23,30"
        let res = try parser.parse(rfcString)
        #expect(res.nthDayOfMonth == [2, 5, 10, 23, 30])
    }

    @available(macOS 15, *)
    @Test(
        "Get next date occurrence from a parsed rrule with only frequency and interval specified",
        arguments: zip(
            [
                "FREQ=DAILY;INTERVAL=3",
                "FREQ=WEEKLY;INTERVAL=2",
                "FREQ=MONTHLY;INTERVAL=5",
                "FREQ=YEARLY",
                "FREQ=WEEKLY"
            ],
            ["20250220", "20250303", "20250717", "20260217", "20250224"]
        )
    )
    func getNextDateOccurrence(rfcString: String, expectedDate: String) throws {
        let startingDate = "20250217"
        let currenDate = "20250217"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = calendar.timeZone

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currenDate) else {
            return
        }

        let rule = try RecurrenceRule(rfcString, calendar: calendar)
        guard let result = try? rule.getNextOccurrence(startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

    @available(macOS 15, *)
    @Test("Get all next date occurrences from a parsed rrule based on count")
    func allNextOccurrences() throws {
        let rfcString = "FREQ=DAILY;COUNT=10"
        let startingDate = "20250217"
        let expectedDates: [String] = [
            "20250217", "20250218", "20250219", "20250220", "20250221", "20250222", "20250223",
            "20250224", "20250225", "20250226"
        ]
        var expectedDatesFormatted: [Date] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = calendar.timeZone

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        for i in expectedDates {
            let date = formatter.date(from: i)!
            expectedDatesFormatted.append(date)
        }

        let rule = try RecurrenceRule(rfcString, calendar: calendar)
        guard let result = try? rule.allOccurrencesSinceStartDate(startDateObj) else {
            return
        }

        #expect(result == expectedDatesFormatted)
    }

    @available(macOS 15, *)
    @Test(
        "Get next date occurrence from a parsed rrule with multiple rule parts",
        arguments: zip(
            ["FREQ=DAILY;INTERVAL=5;COUNT=3", "FREQ=WEEKLY;INTERVAL=1;UNTIL=20250320", "FREQ=DAILY;INTERVAL=2",
             "FREQ=DAILY;COUNT=9"],
            ["20250227", "20250303", "20250227", "20250226"]
        )
    )
    func nextDateOccurrence(rfcString: String, expectedDate: String) throws {
        let startingDate = "20250217"
        let currentDate = "20250225"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = calendar.timeZone

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currentDate) else {
            return
        }

        let rule = try RecurrenceRule(rfcString, calendar: calendar)
        guard let result = try rule.getNextOccurrence(startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

    @available(macOS 15, *)
    @Test(
        "Get next date occurrence from a parsed rrule with BYDAY rule parts",
        arguments: zip(
            ["FREQ=WEEKLY;BYDAY=TU,SA"],
            ["20250301"]
        )
    )
    func nextOccurrenceBydayPart(rfcString: String, expectedDate: String) throws {
        let startingDate = "20250218"
        let currentDate = "20250225"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = calendar.timeZone

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currentDate) else {
            return
        }

        let rule = try RecurrenceRule(rfcString, calendar: calendar)
        guard let result = try rule.getNextOccurrence(startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

    @available(macOS 15, *)
    @Test(
        "Get next date occurrence from a parsed rrule with BYSETPOS rule parts",
        arguments: zip(
            [
                "FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2",
                "FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2,3",
                "FREQ=MONTHLY;BYDAY=TU,TH;BYSETPOS=-1",
                "FREQ=YEARLY;BYDAY=TU;BYSETPOS=2"
            ],
            ["20250310", "20250217", "20250227", "20260113"]
        )
    )
    func nextOccurrenceBySetPosPart(rfcString: String, expectedDate: String) throws {
        let startingDate = "20250210"
        let currentDate = "20250212"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = calendar.timeZone

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currentDate) else {
            return
        }

        let rule = try RecurrenceRule(rfcString, calendar: calendar)
        guard let result = try rule.getNextOccurrence(startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

    @available(macOS 15, *)
    @Test(
        "Get next date occurrence if the first occurence didn't happen yet",
        arguments: zip(
            ["FREQ=DAILY;INTERVAL=5;COUNT=3", "FREQ=WEEKLY;INTERVAL=1;UNTIL=20250320", "FREQ=DAILY;INTERVAL=2",
             "FREQ=MONTHLY;COUNT=9"],
            ["20250707", "20250707", "20250707", "20250707"]
        )
    )
    func firstOccurence(rfcString: String, expectedDate: String) throws {
        let startingDate = "20250707"
        let currentDate = "20250702"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = calendar.timeZone

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currentDate) else {
            return
        }

        let rule = try RecurrenceRule(rfcString, calendar: calendar)
        guard let result = try rule.getNextOccurrence(startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }
}
