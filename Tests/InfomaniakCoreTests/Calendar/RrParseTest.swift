//
//  RrParseTest.swift
//  InfomaniakCore
//
//  Created by Baptiste on 25.02.2025.
//

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
        parser = RruleDecoder(frequency: .daily, interval: 1, calendar: calendar, end: 1, count: 1, byDay: [.monday, .tuesday])
    }

    @Test("Parse FREQ Rule Part", arguments: zip(
        ["MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY"],
        [RruleDecoder.Frequency.minutely, .hourly, .daily, .weekly, .monthly, .yearly]
    ))
    func parseFrequencyRulePart(rfcFrequency: String, expected: RruleDecoder.Frequency) throws {
        let rfcString = "FREQ=\(rfcFrequency)"
        let result = try parser.parse(rfcString)

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
        let result = try parser.parse(rfcString)
        print(result)

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

    @Test("Parses COUNT as a specific occurence limit", arguments: zip(["COUNT=1", "COUNT=5"], [1, 5]))
    func parseCountRulePart(rfcCount: String, expected: Int) throws {
        let rfcString = "FREQ=DAILY;\(rfcCount)"
        let result = try parser.parse(rfcString)

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
        let res = try parser.parse(rfcString)

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
            [RruleDecoder.weekday.monday, .tuesday, .wednesday, .thursday, .friday]
        )
    )
    func parseByDayEveryWeekdayRulePart(rfcByDay: String, expected: RruleDecoder.weekday) throws {
        let rfcString = "FREQ=DAILY;\(rfcByDay)"
        let result = try parser.parse(rfcString)

        #expect(result.byDay == [expected])
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
    func getNextDateOccurence(rfcString: String, expectedDate: String) throws {
        let startingDate = "20250217"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let startDateObj = formatter.date(from: startingDate) else {
            return
        }

        guard let result = try parser.frequencyNextDate(rfcString, startDateObj) else {
            return
        }

        let resultDateString = formatter.string(from: result)
        #expect(resultDateString == expectedDate)
    }

}
