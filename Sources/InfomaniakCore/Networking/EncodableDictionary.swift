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

struct EncodableDictionary: Encodable, Sendable {
    private let dictionary: [String: Encodable & Sendable]

    init(_ dictionary: [String: Encodable & Sendable]) {
        self.dictionary = dictionary
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        for (key, value) in dictionary {
            try container.encode(value, forKey: CodingKeys(stringValue: key))
        }
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int? { return nil }

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }
}
