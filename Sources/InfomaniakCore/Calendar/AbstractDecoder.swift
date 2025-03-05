//  AbstractDecoder.swift
//  InfomaniakCore
//
//  Created by Baptiste on 04.03.2025.
//

import Foundation

public enum Frequency: String, CaseIterable, Codable, Sendable {
    case secondly = "SECONDLY"
    case minutely = "MINUTELY"
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

public enum Weekday: String, CaseIterable, Codable, Sendable {
    case monday = "MO"
    case tuesday = "TU"
    case wednesday = "WE"
    case thursday = "TH"
    case friday = "FR"
    case saturday = "SA"
    case sunday = "SU"
}

public enum Rule: String, CaseIterable, Codable {
    case frequency = "FREQ"
    case interval = "INTERVAL"
    case count = "COUNT"
    case until = "UNTIL"
    case byDay = "BYDAY"
}
