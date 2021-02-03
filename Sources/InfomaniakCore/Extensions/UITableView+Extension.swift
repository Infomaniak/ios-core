//
//  UITableView+Extension.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 30.10.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

extension UITableView {
    public func register(cellView: AnyClass) {
        let name = String(describing: cellView.self)
        register(UINib(nibName: name, bundle: nil), forCellReuseIdentifier: name)
    }

    public func dequeueReusableCell<CellClass : UITableViewCell>(type: CellClass.Type, for indexPath: IndexPath) -> CellClass {
        return dequeueReusableCell(withIdentifier: String(describing: type.self), for: indexPath) as! CellClass
    }
}
