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

@Suite("UTEmailChecker")
public struct UTEmailChecker {
    @Test("Check valid mail", arguments: ["timcook@apple.com", "tim.cook@apple.com", "a@a.a"])
    func valid(mail: String) throws {
        let emailChecker = EmailChecker(email: mail)
        #expect(emailChecker.validate() == true)
    }

    @Test("Check invalid mail", arguments: ["tim.cook@applecom", "timcook@apple", "a@a", "@apple.com"])
    func invalid(mail: String) throws {
        let emailChecker = EmailChecker(email: mail)
        #expect(emailChecker.validate() == false)
    }
}
