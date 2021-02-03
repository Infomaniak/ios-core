//
//  UIButton+Extension.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 11.08.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

public extension UIButton {
    func setLoading(_ loading: Bool, style: UIActivityIndicatorView.Style = .white) {
        self.isEnabled = !loading
        if loading {
            self.setTitle("", for: .disabled)
            let loadingSpinner = UIActivityIndicatorView(style: style)
            loadingSpinner.startAnimating()
            loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
            loadingSpinner.hidesWhenStopped = true
            self.addSubview(loadingSpinner)
            loadingSpinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            loadingSpinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        } else {
            self.setTitle(self.title(for: .normal), for: .disabled)
            for view in self.subviews {
                if view.isKind(of: UIActivityIndicatorView.self) {
                    view.removeFromSuperview()
                }
            }
        }
    }
}
