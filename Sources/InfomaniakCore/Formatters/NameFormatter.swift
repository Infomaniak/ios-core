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

public struct NameFormatter {
    public let fullName: String

    public init(fullName: String) {
        self.fullName = fullName
    }

    public var nameComponents: (givenName: String, familyName: String?) {
        let components = fullName.components(separatedBy: .whitespaces)
        let givenName = components[0]
        let familyName = components.count > 1 ? components[1] : nil
        return (givenName, familyName)
    }

    public var initials: String {
        let initials = [nameComponents.givenName, nameComponents.familyName]
            .compactMap { component in
                if let component,
                   let firstCharacter = removePunctuation(from: component).first {
                    return String(firstCharacter)
                } else {
                    return nil
                }
            }
        return initials.joined().uppercased()
    }

    public var shortName: String {
        let emailChecker = EmailChecker(email: fullName)
        if emailChecker.validate() {
            return fullName.components(separatedBy: "@").first ?? fullName
        }

        return removePunctuation(from: nameComponents.givenName)
    }

    private func removePunctuation(from string: String) -> String {
        let sanitizedString = string.components(separatedBy: CharacterSet.punctuationCharacters).joined(separator: "")
        return sanitizedString.isEmpty ? string : sanitizedString
    }
}
