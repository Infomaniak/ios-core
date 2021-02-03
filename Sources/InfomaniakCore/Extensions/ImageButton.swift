//
//  ImageButton.swift
//  InfomaniakCore
//
//  Created by Ambroise Decouttere on 28.09.2020.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

@IBDesignable
open class ImageButton: UIButton {

    @IBInspectable var imageWidth: CGFloat = 0
    @IBInspectable var imageHeight: CGFloat = 0

    open override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                self.alpha = 0.5
            } else {
                self.alpha = 1.0
            }
        }
    }

    open override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.alpha = 0.5
            } else {
                self.alpha = 1.0
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        var titleSize = CGSize()
        var imageSize = CGSize()
        let contentSize = self.frame.size
        let contentEdgeInsets = self.contentEdgeInsets
        let titleEdgeInsets = self.titleEdgeInsets
        let imageEdgeInsets = self.imageEdgeInsets

        if let titleLabel = self.titleLabel {
            titleLabel.sizeToFit()
            titleSize = titleLabel.frame.size
        }

        if self.imageView != nil {
            imageSize = CGSize(width: imageWidth, height: imageHeight)
        }

        let totalWidth = imageSize.width + titleSize.width + titleEdgeInsets.left + imageEdgeInsets.right
        let offsetLeft = (contentSize.width - totalWidth) / 2.0
        var imageFrame = CGRect(origin: CGPoint(x: offsetLeft, y: 0), size: imageSize)

        imageFrame.origin.y = (contentSize.height - imageSize.height - contentEdgeInsets.top - contentEdgeInsets.bottom - imageEdgeInsets.top - imageEdgeInsets.bottom) / 2.0 + contentEdgeInsets.top + imageEdgeInsets.top
        imageFrame.origin.x = (contentSize.width - imageSize.width - titleSize.width - contentEdgeInsets.left - contentEdgeInsets.right - imageEdgeInsets.left - imageEdgeInsets.right - titleEdgeInsets.left - titleEdgeInsets.right) / 2.0 + contentEdgeInsets.left + titleEdgeInsets.left

        var titleFrame = CGRect(origin: CGPoint(), size: titleSize)

        titleFrame.origin.y = (contentSize.height - titleSize.height - contentEdgeInsets.top - contentEdgeInsets.bottom - titleEdgeInsets.top - titleEdgeInsets.bottom) / 2.0 + contentEdgeInsets.top + titleEdgeInsets.top
        titleFrame.origin.x = imageFrame.origin.x + imageSize.width + imageEdgeInsets.right + titleEdgeInsets.left

        self.imageView?.frame = imageFrame
        self.titleLabel?.frame = titleFrame
    }
}
