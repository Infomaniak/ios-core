//
//  UIColor+Extension.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 09.10.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

extension UIColor {
    public convenience init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1)
    }

    public class func backgroundColor(from userId: Int) -> UIColor {
        let colorIndex = userId % 9
        return UIColor(named: "organisationColor\(colorIndex)", in: Bundle.module, compatibleWith: nil) ?? .darkGray
    }
}
