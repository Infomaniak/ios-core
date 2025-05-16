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
