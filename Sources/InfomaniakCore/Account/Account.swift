//
//  Account.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 16.06.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import Foundation
import InfomaniakLogin

public protocol AccountUpdateDelegate {
    func didUpdateCurrentAccount(_ account: Account)
}

open class Account: Equatable, Codable {

    public var token: ApiToken! {
        didSet {
            userId = token.userId
        }
    }

    public var userId: Int!
    public var user: UserProfile!

    public init(apiToken: ApiToken) {
        self.token = apiToken
        self.userId = apiToken.userId
    }

    public static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.userId == rhs.userId
    }

    enum CodingKeys: CodingKey {
        case userId
        case user
    }
}
