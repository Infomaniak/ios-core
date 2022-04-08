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

import Kingfisher
import UIKit

public protocol InfomaniakUser {
    var id: Int { get }
    var email: String { get }
    var displayName: String { get }
    var avatar: String { get }

    func getAvatar(size: CGSize, completion: @escaping (UIImage) -> Void)
}

public extension InfomaniakUser {
    func getAvatar(size: CGSize = CGSize(width: 40, height: 40), completion: @escaping (UIImage) -> Void) {
        if let url = URL(string: avatar) {
            KingfisherManager.shared.retrieveImage(with: url) { result in
                if let avatarImage = try? result.get().image {
                    completion(avatarImage)
                }
            }
        } else {
            let backgroundColor = UIColor.backgroundColor(from: id)
            completion(UIImage.getInitialsPlaceholder(with: displayName, size: size, backgroundColor: backgroundColor))
        }
    }
}
