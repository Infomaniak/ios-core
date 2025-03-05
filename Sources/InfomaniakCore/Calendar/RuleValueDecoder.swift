//  RuleValueDecoder.swift
//  InfomaniakCore
//
//  Created by Baptiste on 05.03.2025.
//

protocol RuleValueDecoder {
    associatedtype Output
    func decode(_ value: String) throws -> Output
}

enum RuleKey: String {
    case frequency = "FREQ"
    case interval = "INTERVAL"
    case count = "COUNT"
    case until = "UNTIL"
    case byDay = "BYDAY"

    var parser: any RuleValueDecoder {
        switch self {
        case .frequency: return FrequencyParser()
        case .interval: return IntervalParser()
        case .count: return CountParser()
        case .until: return UntilParser()
        case .byDay: return ByDayParser()
        }
    }
}
