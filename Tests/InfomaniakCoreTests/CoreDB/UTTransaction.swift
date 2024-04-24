/*
 Infomaniak Core - iOS
 Copyright (C) 2023 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreDB
import RealmSwift
import XCTest

/// Wrapping a `InMemoryFileDB` for realm access
struct MCKRealmAccessible: RealmAccessible {
    let datasource: InMemoryFileDB

    init(count: Int) {
        datasource = InMemoryFileDB(count: count)
    }

    var allFiles: [MCKFile] {
        datasource.files
    }

    // MARK: RealmAccessible

    func getRealm() -> Realm {
        let realm = datasource.inMemoryRealm
        realm.refresh()
        return realm
    }
}

/// Ersatz of a file for testing
final class MCKFile: Object {
    @Persisted(primaryKey: true) public var uid = UUID().uuidString
    @Persisted public var name: String
    @Persisted public var path: String
    @Persisted public var index: Int
    @Persisted public var isEvenIndex: Bool

    override init() {
        // required by realm
    }

    init(uid: String = UUID().uuidString, name: String, path: String, index: Int) {
        self.uid = uid
        self.name = name
        self.path = path
        self.index = index
        isEvenIndex = index % 2 == 0
    }
}

/// Some in memory database with linked managed types
struct InMemoryFileDB {
    public let count: Int

    /// Files generated at init. Added to `inMemoryRealm`
    public var files = [MCKFile]()

    var inMemoryRealm: Realm {
        let identifier = "MockRealm"
        let configuration = Realm.Configuration(inMemoryIdentifier: identifier, objectTypes: [
            MCKFile.self,
        ])

        // Sir, this is a unit test.
        // swiftlint:disable:next force_try
        let realm = try! Realm(configuration: configuration)
        return realm
    }

    public init(count: Int) {
        assert(count > 0, "maxCount should be positive integer. Got:\(count)")
        self.count = count

        files = (0 ... count - 1).enumerated().map { node in
            buildFile(index: node.element)
        }

        // Sir, this is a unit test.
        // swiftlint:disable:next force_try
        try! inMemoryRealm.write {
            for file in files {
                self.inMemoryRealm.add(file, update: .modified)
            }
        }
    }

    static let wordDictionary = [
        "Lorem",
        "ipsum",
        "dolor",
        "sit",
        "amet",
        "consectetur",
        "adipiscing",
        "elit",
        "sed",
        "do",
        "eiusmod",
        "tempor",
        "incididunt",
        "ut",
        "labore",
        "et",
        "dolore",
        "magna",
        "aliqua"
    ]

    static let pathDictionary = [
        "/bin",
        "/boot",
        "/boot/EFI",
        "/dev",
        "/dev/null",
        "/etc",
        "/mnt",
        "/mnt/cdrom",
        "/opt",
        "/opt/local/bin"
    ]

    func buildFile(index: Int) -> MCKFile {
        MCKFile(uid: randomID, name: randomWord, path: randomPath, index: index)
    }

    var randomWord: String {
        Self.wordDictionary.randomElement()!
    }

    var randomPath: String {
        Self.pathDictionary.randomElement()!
    }

    var randomID: String {
        UUID().uuidString
    }
}

final class UTTransaction: XCTestCase {
    // MARK: object transaction

    func testFetchObjectFromPrimaryKey() {
        // GIVEN
        let count = 50
        let accessible = MCKRealmAccessible(count: count)
        let executor = TransactionExecutor(realmAccessible: accessible)
        let firstObjectUID = accessible.allFiles.first!.uid

        // Sanity check
        XCTAssertEqual(count, accessible.allFiles.count)

        // WHEN
        guard let fetchedObject = executor.fetchObject(ofType: MCKFile.self, forPrimaryKey: firstObjectUID) else {
            XCTFail("Unable to fetch object for UID \(firstObjectUID)")
            return
        }

        // THEN
        XCTAssertEqual(fetchedObject.uid, firstObjectUID)
    }

    func testFetchObjectFromFiltering() {
        // GIVEN
        let count = 50
        let accessible = MCKRealmAccessible(count: count)
        let executor = TransactionExecutor(realmAccessible: accessible)
        let firstObjectIndex = accessible.allFiles.first!.index

        // Sanity check
        XCTAssertEqual(count, accessible.allFiles.count)

        // WHEN
        guard let fetchedObject = executor.fetchObject(ofType: MCKFile.self, filtering: { faultedCollection in
            faultedCollection.filter("index == %@", NSNumber(value: firstObjectIndex)).first
        }) else {
            XCTFail("Unable to fetch and filter object for index \(firstObjectIndex)")
            return
        }

        // THEN
        XCTAssertEqual(fetchedObject.index, firstObjectIndex)
    }

    // MARK: objects transaction

    func testFetchAll() {
        // GIVEN
        let count = 50
        let accessible = MCKRealmAccessible(count: count)
        let executor = TransactionExecutor(realmAccessible: accessible)

        // Sanity check
        XCTAssertEqual(count, accessible.allFiles.count)

        // WHEN
        let results = executor.fetchResults(ofType: MCKFile.self) { faultedResults in
            return faultedResults
        }

        // THEN
        XCTAssertEqual(results.count, accessible.allFiles.count)
    }

    func testFetchObjectsFromFiltering() {
        // GIVEN
        let count = 50
        let accessible = MCKRealmAccessible(count: count)
        let executor = TransactionExecutor(realmAccessible: accessible)

        // Sanity check
        XCTAssertEqual(count, accessible.allFiles.count)

        // WHEN
        let results = executor.fetchResults(ofType: MCKFile.self) { faultedResults in
            let evenOnlyPredicate = NSPredicate(format: "isEvenIndex == TRUE")
            return faultedResults.filter(evenOnlyPredicate)
        }

        // THEN
        XCTAssertEqual(results.count, count / 2, "we expect half of the original set of objects, got \(results.count)")
    }

    // MARK: write transaction

    func testWriteTransactionRemoveAll() {
        // GIVEN
        let count = 50
        let accessible = MCKRealmAccessible(count: count)
        let executor = TransactionExecutor(realmAccessible: accessible)

        // Sanity check
        XCTAssertEqual(count, accessible.allFiles.count)

        // WHEN
        do {
            try executor.writeTransaction { realm in
                let allFiles = realm.objects(MCKFile.self)
                realm.delete(allFiles)
            }

            let allFiles = executor.fetchResults(ofType: MCKFile.self) { $0 }

            // THEN
            XCTAssertEqual(allFiles.count, 0, "we expect zero files remaining, got \(allFiles.count)")
        } catch {
            XCTFail("Unexpected error :\(error)")
        }
    }
}
