/*
 Infomaniak Core - iOS
 Copyright (C) 2023 Infomaniak Network SA

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

import Testing
@testable import InfomaniakCore

@Suite("ApiEnvironment Tests")
struct UTApiEnvironment {

    @Test("Production environment host")
    func testProductionHost() {
        let env = ApiEnvironment.prod
        #expect(env.host == "infomaniak.com")
        #expect(env.apiHost == "api.infomaniak.com")
        #expect(env.managerHost == "manager.infomaniak.com")
    }

    @Test("Preproduction environment host")
    func testPreproductionHost() {
        let env = ApiEnvironment.preprod
        #expect(env.host == "preprod.dev.infomaniak.ch")
        #expect(env.apiHost == "api.preprod.dev.infomaniak.ch")
        #expect(env.managerHost == "manager.preprod.dev.infomaniak.ch")
    }

    @Test("Custom host environment")
    func testCustomHost() {
        let env = ApiEnvironment.customHost("custom.example.com")
        #expect(env.host == "custom.example.com")
        #expect(env.apiHost == "api.custom.example.com")
        #expect(env.managerHost == "manager.custom.example.com")
    }

    @Test("Custom orphan host environment")
    func testCustomOrphanHost() {
        let env = ApiEnvironment.customHost("orphan.example.com")
        #expect(env.host == "orphan.example.com")
        #expect(env.apiHost == "orphan.example.com")
        #expect(env.managerHost == "orphan.example.com")
    }

    @Test("Current environment defaults to production")
    func testCurrentEnvironment() {
        #expect(ApiEnvironment.current == .prod)
    }

    @Test("Environment equality")
    func testEnvironmentEquality() {
        #expect(ApiEnvironment.prod == ApiEnvironment.prod)
        #expect(ApiEnvironment.preprod == ApiEnvironment.preprod)
        #expect(ApiEnvironment.customHost("test") == ApiEnvironment.customHost("test"))
        #expect(ApiEnvironment.prod != ApiEnvironment.preprod)
        #expect(ApiEnvironment.prod != ApiEnvironment.customHost("test"))
    }

    @Test("Environment hashability")
    func testEnvironmentHashability() {
        let prod1 = ApiEnvironment.prod
        let prod2 = ApiEnvironment.prod
        let preprod = ApiEnvironment.preprod
        let custom1 = ApiEnvironment.customHost("test")
        let custom2 = ApiEnvironment.customHost("test")

        #expect(prod1.hashValue == prod2.hashValue)
        #expect(prod1.hashValue != preprod.hashValue)
        #expect(custom1.hashValue == custom2.hashValue)
    }
}
