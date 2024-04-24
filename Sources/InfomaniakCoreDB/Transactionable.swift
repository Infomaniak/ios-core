/*
 Infomaniak Core - iOS
 Copyright (C) 2024 Infomaniak Network SA

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

import Foundation
import RealmSwift

/// Something that standardises the DB transactions API across mobile apps.
///
/// Still using Realm types, but this "seam" would be a perfect place to abstract DB vendor.
///
public protocol Transactionable {
    /// Fetches one object form a DB from primary key.
    ///
    /// The realm is now completely hidden.
    ///
    /// - Parameters:
    ///   - type: The type of the object queried. Defines the return type.
    ///   - key: The primary key used to identify a specific element.
    /// - Returns: A matched entity if any
    func fetchObject<Element: Object, KeyType>(ofType type: Element.Type,
                                               forPrimaryKey key: KeyType) -> Element?

    /// Fetches one object form a DB by filtering.
    ///
    /// The realm is now completely hidden.
    ///
    /// - Parameters:
    ///   - type: The type of the object queried. Defines the return type.
    ///   - filtering: The closure to filter the one element to be returned.
    /// - Returns: A matched entity if any
    func fetchObject<Element: RealmFetchable>(ofType type: Element.Type,
                                              filtering: (Results<Element>) -> Element?) -> Element?

    /// Fetches a faulted realm collection.
    ///
    /// The realm is now completely hidden.
    ///
    /// - Parameters:
    ///   - type: The type of the object queried. Defines the return type.
    ///   - filtering: The closure to filter, sort faulted elements.
    /// - Returns: A faulted realm collection.
    func fetchResults<Element: RealmFetchable>(ofType type: Element.Type,
                                               filtering: (Results<Element>) -> Results<Element>) -> Results<Element>

    /// Provides a writable realm within a closure. Forwards swift errors.
    ///
    /// Not masking realm yet. For write transactions this is only a first step.
    ///
    /// - Parameter realmClosure: The closure to put the transaction into
    func writeTransaction(withRealm realmClosure: (Realm) throws -> Void) throws
}
