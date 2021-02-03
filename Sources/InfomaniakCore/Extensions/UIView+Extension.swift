//
//  UIView+Extension.swift
//  InfomaniakCore
//
//  Created by Ambroise Decouttere on 28.09.2020.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

public extension UIView {

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    func roundCorners(corners: CACornerMask, radius: CGFloat) {
        self.clipsToBounds = false
        self.layer.cornerRadius = radius
        #if !os(tvOS)
            self.layer.maskedCorners = corners
        #endif
    }

    func addShadow(elevation: Double = 1) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.23118 * elevation - 0.03933)
        self.layer.shadowOpacity = 0.17
        self.layer.shadowRadius = CGFloat(0.666920 * elevation - 0.001648)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }

}
