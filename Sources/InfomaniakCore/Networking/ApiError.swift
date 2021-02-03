//
//  ApiError.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 14.08.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import Foundation

open class ApiError: Codable, Error {
    public var code: String
    public var description: String
}
