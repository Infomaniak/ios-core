/*
 Infomaniak Core - iOS
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import XCTest

/// Example class that protects access to a property.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class MCKSendableProperty: XCTestCase {
    @SendableProperty var protectedString: String?
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class UTSendableProperty: XCTestCase {
    func testMutateToNil() async {
        // GIVEN
        let mckSendableClass = MCKSendableProperty()
        mckSendableClass.protectedString = "the fox jumps over the lazy dog"
        XCTAssertNotNil(mckSendableClass.protectedString, "Sanity check")

        // WHEN
        let t = Task.detached {
            mckSendableClass.protectedString = nil
        }

        _ = await t.result

        // THEN
        XCTAssertNil(mckSendableClass.protectedString, "The mutation should be reflected")
    }

    func testMutateConcurent() async {
        // GIVEN
        let mckSendableClass = MCKSendableProperty()
        mckSendableClass.protectedString = nil
        XCTAssertNil(mckSendableClass.protectedString, "Sanity check")

        // WHEN
        let t = Task.detached {
            mckSendableClass.protectedString = "t"
        }

        let u = Task.detached {
            mckSendableClass.protectedString = "u"
        }

        let v = Task.detached {
            mckSendableClass.protectedString = "v"
        }

        _ = await t.result
        _ = await u.result
        _ = await v.result

        // THEN
        XCTAssertNotNil(mckSendableClass.protectedString, "The mutation should be reflected")
    }

    func testMutateSerial() async {
        // GIVEN
        let mckSendableClass = MCKSendableProperty()
        mckSendableClass.protectedString = nil
        XCTAssertNil(mckSendableClass.protectedString, "Sanity check")

        // WHEN
        let t = Task.detached {
            mckSendableClass.protectedString = "t"

            let u = Task.detached {
                mckSendableClass.protectedString = "u"

                let v = Task.detached {
                    mckSendableClass.protectedString = "v"
                }
                _ = await v.result
            }
            _ = await u.result
        }
        _ = await t.result

        // THEN
        XCTAssertNotNil(mckSendableClass.protectedString, "The mutation should be reflected")
        XCTAssertEqual(mckSendableClass.protectedString, "v", "expecting to access the last value mutated")
    }
}
