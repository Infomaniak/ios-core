//
//  UIViewController+Extension.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 31.01.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

public extension UIViewController {

    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func okAlert(title: String, message: String?, completion: (() -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completion?() }))
        self.present(alert, animated: true)
    }

}
