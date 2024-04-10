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

/// Something that standardises the transactions API, on a specific realm.
public protocol Transactionable {
    /// Provides a writable realm within a closure. Forwards swift errors.
    /// - Parameter realmClosure: The closure to put the transaction into
    func writeTransaction(withRealm realmClosure: (Realm) throws -> Void) throws

    /// Fetches one object form a realm. Closure style can adapt to existing code.
    ///
    /// The realm is never writable, will throw if mutation occurs within `realmClosure`
    ///
    /// - Parameters:
    ///   - type: The type of the object queried. Defines the return type.
    ///   - realmClosure:  The closure to put the fetch, filter, sort operations
    /// - Returns: A matched entity if any
    func fetchObject<Element: Object>(ofType type: Element.Type,
                                      withRealm realmClosure: (Realm) -> Element?) -> Element?

    /// Fetches a faulted realm collection. Closure style can adapt to existing code.
    ///
    /// The realm is never writable, will throw if mutation occurs within `realmClosure`
    ///
    /// - Parameters:
    ///   - type: The type of the object queried. Defines the return type.
    ///   - realmClosure: The closure to put the fetch, filter, sort operations
    /// - Returns: A faulted realm collection.
    func fetchResults<Element: RealmFetchable>(ofType type: Element.Type,
                                               withRealm realmClosure: (Realm) -> Results<Element>) -> Results<Element>
}
