/*
 Infomaniak Core - iOS
 Copyright (C) 2023 Infomaniak Network SA

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

@Suite("RrParseTest")
struct RrParseTest {
    let calendar: Calendar
    let parser: RruleDecoder

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        self.calendar = calendar
        parser = RruleDecoder()
    }

    @Test("Parse FREQ Rule Part", arguments: zip(
        ["MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY"],
        [Frequency.minutely, .hourly, .daily, .weekly, .monthly, .yearly]
    ))
    func parseFrequencyRulePart(rfcFrequency: String, expected: Frequency) throws {
        let rfcString = "FREQ=\(rfcFrequency)"
        let result = RruleDecoder()
        try parser.parse(rfcString, result)

        #expect(result.frequency == expected)
    }

    @Test("Throws an error for invalid FREQ Rule Part")
    func returnsNilForInvalidFrequencyRulePart() throws {
        #expect(throws: NSError.self) {
            try parser.parse("FREQ=FOOBAR")
        }
    }

    @Test("Parse INTERVAL Rule Part", arguments: zip(["INTERVAL=1", "INTERVAL=2", "INTERVAL=10"], [1, 2, 10]))
    func parseIntervalRulePart(rfcInterval: String, expected: Int) throws {
        let rfcString = "FREQ=DAILY;\(rfcInterval)"
        let result = RruleDecoder()
        try parser.parse(rfcString, result)

        #expect(result.interval == expected)
    }

    @Test("Throws an error for invalid INTERVAL Rule Part", arguments: [
        "INTERVAL=", "INTERVAL=-1", "INTERVAL=0", "INTERVAL=foo"
    ])
    func throwsErrorForInvalidIntervalRuleParrt(invalidInterval: String) throws {
        let rfcString = "FREQ=DAILY;\(invalidInterval)"
        #expect(throws: NSError.self) {
            try parser.parse(rfcString)
        }
    }

    @Test("Parses COUNT as a specific occurrence limit", arguments: zip(["COUNT=1", "COUNT=5"], [1, 5]))
    func parseCountRulePart(rfcCount: String, expected: Int) throws {
        let rfcString = "FREQ=DAILY;\(rfcCount)"
        let result = RruleDecoder()
        try parser.parse(rfcString, result)

        #expect(result.count == expected)
    }

    @Test("Throws an error for invalid COUNT Rule Part", arguments: ["COUNT=", "COUNT=-2", "COUNT=1- ", "COUNT=foobar"])
    func throwsErrorForInvalidCountRulePart(invalidCount: String) throws {
        let rfcString = "FREQ=DAILY;\(invalidCount)"
        #expect(throws: NSError.self) {
            try parser.parse(rfcString)
        }
    }

    @Test("Parse UNTIL DATE Rule Part")
    func parseUntilDateRulePart() throws {
        let rfcString = "FREQ=DAILY;UNTIL=20250111"
        let expected = Date(timeIntervalSince1970: 1_736_553_600)
        let res = RruleDecoder()
        try parser.parse(rfcString, res)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let result = formatter.date(from: String(res.end!)) else {
            return
        }

        #expect(result.timeIntervalSince1970 == expected.timeIntervalSince1970)
    }

    @Test("Throws an error for invalid UNTIL Rule Part", arguments: ["UNTIL=20251350", "UNTIL=foobar", "UNTIL=1"])
    func throwsErrorForInvalidUntilRulePart(invalidString: String) throws {
        let rfcString = "FREQ=DAILY;\(invalidString)"
        #expect(throws: NSError.self) {
            try parser.parse(rfcString)
        }
    }

    @Test("Throws an error when both UNTIL and COUNT are specified")
    func throwsErrorWhenBothUntilAndCountAreSpecified() throws {
        let rfcString = "FREQ=DAILY;UNTIL=20200101T120000Z;COUNT=1"
        #expect(throws: NSError.self) {
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
        let result = RruleDecoder()
        try parser.parse(rfcString, result)

        #expect(result.byDay == [expected])
    }

    @Test("Parse BYDAY with multiple weekdays Rule Part")
    func parseByDayEveryWeekdayRulePart() throws {
        let rfcString = "FREQ=DAILY;BYDAY=MO,TH"
        let result = RruleDecoder()
        try parser.parse(rfcString, result)

        #expect(result.byDay == [.monday, .thursday])
    }

    @Test("Parse BYSETPOS Rule Part")
    func parseBySetPosRulePart() throws {
        let rfcString = "FREQ=MONTHLY;BYSETPOS=2,5,10,23,30"
        let res = RruleDecoder()
        try parser.parse(rfcString, res)
        guard let result = res.bySetPos else {
            return
        }
        #expect(result == [2, 5, 10, 23, 30])
    }

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
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currenDate) else {
            return
        }

        guard let result = try? parser.getNextOccurrence(rfcString, startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

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
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        for i in expectedDates {
            let date = formatter.date(from: i)!
            expectedDatesFormatted.append(date)
        }

        guard let result = try? parser.allNextOccurrences(rfcString, startDateObj) else {
            return
        }

        #expect(result == expectedDatesFormatted)
    }

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
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currentDate) else {
            return
        }

        guard let result = try parser.getNextOccurrence(rfcString, startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

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
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currentDate) else {
            return
        }

        guard let result = try parser.getNextOccurrence(rfcString, startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

    @Test(
        "Get next date occurrence from a parsed rrule with BYSETPOS rule parts",
        arguments: zip(
            ["FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2", "FREQ=MONTHLY;BYDAY=TU;BYSETPOS=-1"],
            ["20250310", "20250225"]
        )
    )
    func nextOccurrenceBySetPosPart(rfcString: String, expectedDate: String) throws {
        let startingDate = "20250210"
        let currentDate = "20250212"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let currentDateObj = formatter.date(from: currentDate) else {
            return
        }

        guard let result = try parser.getNextOccurrence(rfcString, startDateObj, currentDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }
}
