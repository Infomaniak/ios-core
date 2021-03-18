//
//  String+Extension.swift
//
//
//  Created by Elena Willen on 18/03/2021.
//

import Foundation

public extension String {

    public var initials: String {
        let words = self.split(separator: " ")
        guard words.count > 0, let firstLetter = words[0].first else {
            return ""
        }
        var initials = String(firstLetter).capitalized
        if words.count > 1, let secondLetter = words[1].first  {
            initials = initials + String(secondLetter).capitalized
        }
        return initials
    }
}
