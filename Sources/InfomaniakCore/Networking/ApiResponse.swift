//
//  ApiResponse.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 15.06.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import Foundation

public enum ApiResult: String, Codable {
    case success
    case error
}

public class EmptyResponse: Codable {

}

open class ApiResponse<ResponseContent : Codable>: Codable {

    public let result: ApiResult
    public let data: ResponseContent?
    public let error: ApiError?
    public let total: Int?
    public let pages: Int?
    public let page: Int?
    public let itemsPerPage: Int?

    enum CodingKeys: String, CodingKey {
        case result
        case data
        case error
        case total
        case pages
        case page
        case itemsPerPage = "items_per_page"
    }
}
