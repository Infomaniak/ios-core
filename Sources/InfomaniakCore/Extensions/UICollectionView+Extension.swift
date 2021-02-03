//
//  UICollectionView+Extension.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 13.01.21.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import Foundation

import UIKit

extension UICollectionView {
    public func register(cellView: AnyClass) {
        let name = String(describing: cellView.self)
        register(UINib(nibName: name, bundle: nil), forCellWithReuseIdentifier: name)
    }

    public func dequeueReusableCell<CellClass : UICollectionViewCell>(type: CellClass.Type, for indexPath: IndexPath) -> CellClass {
        return dequeueReusableCell(withReuseIdentifier: String(describing: type.self), for: indexPath) as! CellClass
    }
}
