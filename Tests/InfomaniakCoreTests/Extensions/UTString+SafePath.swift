/*
 Infomaniak Core - iOS
 Copyright (C) 2026 Infomaniak Network SA

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

@Suite
struct UTStringSafePathExtension {
    @Test("Legit name and extension are preserved")
    func safeLastPathComponentPreservesLegitName() {
        #expect("invoice.pdf".safeLastPathComponent == "invoice.pdf")
    }

    @Test("Legit name and extension are preserved with path removed")
    func safeLastPathComponentPreservesLegitNameAndRemovesPath() {
        #expect("./folder/invoice.pdf".safeLastPathComponent == "invoice.pdf")
    }

    @Test("Traversal segments are stripped")
    func safeLastPathComponentStripsTraversal() {
        #expect("../../../evil.txt".safeLastPathComponent == "evil.txt")
    }

    @Test("Percent encoded segments are cleaned")
    func safeLastPathComponentStripsPercentEncoded() {
        #expect("./path/Capture%20d%27%C3%A9cran.png".safeLastPathComponent == "Capture d'écran.png")
        #expect("./path/%2E%2E/evil.txt".safeLastPathComponent == "evil.txt")
    }

    @Test("Escape char are cleaned")
    func safeLastPathComponentStripsEscaped() {
        #expect("..\\/..\\/..\\/evil.txt".safeLastPathComponent == "evil.txt")
    }

    @Test("Path exceeding PATH_MAX returns nil")
    func safeLastPathComponentReturnsNilForPathThatIsTooLong() {
        let path = String(repeating: "a", count: Int(PATH_MAX))

        #expect(path.safeLastPathComponent == nil)
    }

    @Test("Directory traversal component returns nil")
    func safeLastPathComponentReturnsNilForParentDirectory() {
        #expect("..".safeLastPathComponent == nil)
    }

    @Test("Current directory component returns nil")
    func safeLastPathComponentReturnsNilForCurrentDirectory() {
        #expect(".".safeLastPathComponent == nil)
    }

    @Test("Root path returns nil")
    func safeLastPathComponentReturnsNilForRootPath() {
        #expect("/".safeLastPathComponent == nil)
    }

    @Test("Separator-only path returns nil")
    func safeLastPathComponentReturnsNilForSeparatorOnlyPath() {
        #expect("///".safeLastPathComponent == nil)
    }

    @Test("Empty string returns nil")
    func safeLastPathComponentReturnsNilForEmptyString() {
        #expect("".safeLastPathComponent == nil)
    }
}
