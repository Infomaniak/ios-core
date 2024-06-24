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
import InfomaniakCore
import RealmSwift

/// Shared protected DB transaction implementation.
///
///  Only write transactions are protected from sudden termination, will extend to read if required.
public struct TransactionExecutor: Transactionable {
    let realmAccessible: RealmAccessible

    public init(realmAccessible: RealmAccessible) {
        self.realmAccessible = realmAccessible
    }

    // MARK: Transactionable

    public func fetchObject<Element: Object, KeyType>(ofType type: Element.Type, forPrimaryKey key: KeyType) -> Element? {
        autoreleasepool {
            let realm = realmAccessible.getRealm()
            let object = realm.object(ofType: type, forPrimaryKey: key)
            return object
        }
    }

    public func fetchObject<Element: RealmFetchable>(ofType type: Element.Type,
                                                     filtering: (Results<Element>) -> Element?) -> Element? {
        autoreleasepool {
            let realm = realmAccessible.getRealm()
            let objects = realm.objects(type)
            let filteredObject = filtering(objects)
            return filteredObject
        }
    }

    public func fetchResults<Element: RealmFetchable>(
        ofType type: Element.Type,
        filtering: (RealmSwift.Results<Element>) -> RealmSwift.Results<Element>
    ) -> RealmSwift.Results<Element> {
        autoreleasepool {
            let realm = realmAccessible.getRealm()
            let objects = realm.objects(type)
            let filteredCollection = filtering(objects)
            return filteredCollection
        }
    }

    public func writeTransaction(withRealm realmClosure: (Realm) throws -> Void) throws {
        try autoreleasepool {
            let expiringActivity = ExpiringActivity()
            expiringActivity.start()
            defer {
                expiringActivity.endAll()
            }

            let realm = realmAccessible.getRealm()
            try realm.safeWrite {
                try realmClosure(realm)
            }
        }
    }
}
