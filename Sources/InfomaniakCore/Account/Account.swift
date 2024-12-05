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

import Foundation
import InfomaniakLogin

public protocol AccountUpdateDelegate: AnyObject {
    func didUpdateCurrentAccount(_ account: Account)
}

open class Account: Codable {
    public var token: ApiToken! {
        didSet {
            if let token = token {
                userId = token.userId
            }
        }
    }

    public var isConnected: Bool {
        return token != nil
    }

    public var userId: Int
    public var user: UserProfile!

    public init(apiToken: ApiToken) {
        token = apiToken
        userId = apiToken.userId
    }
}

extension Account: Equatable {
    public static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.userId == rhs.userId
    }
}

extension Account: Identifiable {
    public var id: Int { return userId }
}

extension Account: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
