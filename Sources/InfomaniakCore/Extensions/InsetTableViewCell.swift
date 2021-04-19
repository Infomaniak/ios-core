/*
Infomaniak Core - iOS
Copyright (C) 2021 Infomaniak Network SA

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
