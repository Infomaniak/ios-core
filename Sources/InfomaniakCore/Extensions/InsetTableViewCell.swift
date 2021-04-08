//
//  InsetTableViewCell.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 18.05.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

open class InsetTableViewCell: UITableViewCell {

    @IBOutlet weak open var titleLabel: UILabel!
    @IBOutlet weak open var accessoryImageView: UIImageView!
    @IBOutlet weak open var topConstraint: NSLayoutConstraint?
    @IBOutlet weak open var bottomConstraint: NSLayoutConstraint?
    @IBOutlet weak open var contentInsetView: UIView!
    @IBOutlet weak open var separator: UIView?

    open override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = UIView()
    }

    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selectionStyle != .none {
            if animated {
                UIView.animate(withDuration: 0.1) {
                    self.contentInsetView.backgroundColor = selected ? InfomaniakCoreAsset.backgroundCardViewSelected.color : InfomaniakCoreAsset.backgroundCardView.color
                }
            } else {
                contentInsetView.backgroundColor = selected ? InfomaniakCoreAsset.backgroundCardViewSelected.color : InfomaniakCoreAsset.backgroundCardView.color
            }
        } else {
            contentInsetView.backgroundColor = InfomaniakCoreAsset.backgroundCardView.color
        }
    }

    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if selectionStyle != .none {
            if animated {
                UIView.animate(withDuration: 0.1) {
                    self.contentInsetView.backgroundColor = highlighted ? InfomaniakCoreAsset.backgroundCardViewSelected.color : InfomaniakCoreAsset.backgroundCardView.color
                }
            } else {
                contentInsetView.backgroundColor = highlighted ? InfomaniakCoreAsset.backgroundCardViewSelected.color : InfomaniakCoreAsset.backgroundCardView.color
            }
        } else {
            contentInsetView.backgroundColor = InfomaniakCoreAsset.backgroundCardView.color
        }
    }

    open func initWithPositionAndShadow(isFirst: Bool = false, isLast: Bool = false, elevation: Double = 0, radius: CGFloat = 10) {
        if isLast && isFirst {
            separator?.isHidden = true
            topConstraint?.constant = 8
            bottomConstraint?.constant = 8
            contentInsetView.roundCorners(corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner], radius: radius)
        } else if isFirst {
            separator?.isHidden = false
            topConstraint?.constant = 8
            bottomConstraint?.constant = 0
            contentInsetView.roundCorners(corners: [.layerMaxXMinYCorner, .layerMinXMinYCorner], radius: radius)
        } else if isLast {
            separator?.isHidden = true
            topConstraint?.constant = 0
            bottomConstraint?.constant = 8
            contentInsetView.roundCorners(corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner], radius: radius)
        } else {
            separator?.isHidden = false
            topConstraint?.constant = 0
            bottomConstraint?.constant = 0
            contentInsetView.roundCorners(corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner], radius: 0)
        }
        contentInsetView.addShadow(elevation: elevation)
    }

}
