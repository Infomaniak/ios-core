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
import InfomaniakCore
import Testing

@Suite("UTNameFormatter")
struct UTNameFormatter {
    @Test("Extract short names from various full names", arguments: [
        ("Tim Cook", "Tim"),
        ("Tim.Cook", "TimCook"),
        ("tim.cook@apple.com", "tim.cook"),
        ("Antoine de Saint-Exupéry", "Antoine"),
        (".", ".")
    ])
    func shortNames(input: String, expected: String) throws {
        let nameFormatter = NameFormatter(fullName: input)
        #expect(
            nameFormatter.shortName == expected,
            "Expected '\(expected)' for input '\(input)' but got '\(nameFormatter.shortName)'"
        )
    }

    @Test("Extract initials from various full names", arguments: [
        ("Tim Cook", "TC"),
        ("Tim", "T"),
        ("Tim.Cook", "T"),
        ("tim.cook@apple.com", "T"),
        ("Antoine de Saint-Exupéry", "AD"),
        (".", ".")
    ])
    func initials(input: String, expected: String) throws {
        let nameFormatter = NameFormatter(fullName: input)
        #expect(
            nameFormatter.initials == expected,
            "Expected '\(expected)' for input '\(input)' but got '\(nameFormatter.initials)'"
        )
    }
}
