//
//  TitleSizeAdjustingNavigationController.swift
//  InfomaniakCore
//
//  Created by Ambroise Decouttere on 07.10.2020.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

/// A `UINavigationController` that adjusts the font size of its large title labels to fit its content
open class TitleSizeAdjustingNavigationController: UINavigationController {
    var minimumScaleFactor: CGFloat = 0.5

    #if !os(tvOS)
        public override func viewDidLayoutSubviews() {
            guard navigationBar.prefersLargeTitles else { return }

            updateLargeTitleLabels()
        }
    #endif

    private func updateLargeTitleLabels() {
        largeTitleLabels().forEach {
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = minimumScaleFactor
        }
    }

    private func largeTitleLabels() -> [UILabel] {
        let subviews = recursiveSubviews(of: navigationBar)
        let labels = subviews.compactMap { $0 as? UILabel }
        let titles = viewControllers.compactMap { $0.navigationItem.title } + viewControllers.compactMap { $0.title }
        let titleLabels = labels.filter {
            if let text = $0.text, titles.contains(text) {
                return true
            }
            return false
        }
        // 'large' title labels are identified by comparing font size
        let titleLabelFontSizes = titleLabels.map { $0.font.pointSize }
        let largeTitleLabelFontSize = titleLabelFontSizes.max()
        let largeTitleLabels = titleLabels.filter { $0.font.pointSize == largeTitleLabelFontSize }
        return largeTitleLabels
    }

    private func recursiveSubviews(of view: UIView) -> [UIView] {
        var result = [UIView]()
        for subview in view.subviews {
            result.append(subview)
            result.append(contentsOf: recursiveSubviews(of: subview))
        }
        return result
    }
}
