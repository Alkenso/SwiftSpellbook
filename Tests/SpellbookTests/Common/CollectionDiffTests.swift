import SpellbookFoundation
import XCTest

class CollectionDiffTests: XCTestCase {
    func test_array() {
        let diff = CollectionDiff(from: [1, 2, 3], to: [4, 2])
        XCTAssertEqual(Set(diff.added), [4])
        XCTAssertEqual(Set(diff.updated), [])
        XCTAssertEqual(Set(diff.removed), [1, 3])
        XCTAssertEqual(Set(diff.unchanged), [2])
    }
    
    func test_update() {
        struct Foo: Hashable {
            var id: Int
            var value: String
        }
        
        let diff = CollectionDiff(
            from: [Foo(id: 1, value: "q"), Foo(id: 2, value: "w"), Foo(id: 3, value: "e"), ],
            to: [Foo(id: 1, value: "q"), Foo(id: 2, value: "ww"), Foo(id: 4, value: "ee"), ],
            similarBy: \.id
        )
        XCTAssertEqual(Set(diff.added), [Foo(id: 4, value: "ee")])
        XCTAssertEqual(Set(diff.updated), [.unchecked(old: Foo(id: 2, value: "w"), new: Foo(id: 2, value: "ww"))])
        XCTAssertEqual(Set(diff.removed), [Foo(id: 3, value: "e")])
        XCTAssertEqual(Set(diff.unchanged), [Foo(id: 1, value: "q")])
    }

    func test_duplicates() {
        let added = CollectionDiff(from: [1], to: [1, 1])
        XCTAssertEqual(added.added, [1])
        XCTAssertEqual(added.unchanged, [1])
        XCTAssertEqual(added.removed, [])

        let removed = CollectionDiff(from: [1, 1], to: [1])
        XCTAssertEqual(removed.added, [])
        XCTAssertEqual(removed.unchanged, [1])
        XCTAssertEqual(removed.removed, [1])

        struct Item: Equatable {
            var id: Int
            var value: String
        }
        let identities = CollectionDiff(
            from: [Item(id: 1, value: "a"), Item(id: 1, value: "b")],
            to: [Item(id: 1, value: "a"), Item(id: 1, value: "c")],
            similarBy: \.id
        )
        XCTAssertEqual(identities.added, [])
        XCTAssertEqual(identities.unchanged, [Item(id: 1, value: "a")])
        XCTAssertEqual(
            identities.updated,
            [.unchecked(old: Item(id: 1, value: "b"), new: Item(id: 1, value: "c"))]
        )
        XCTAssertEqual(identities.removed, [])
    }
    
    func test_dict() {
        let diff = DictionaryDiff(from: [1: "q", 2: "w", 3: "e"], to: [1: "q", 2: "ww", 4: "r"])
        XCTAssertEqual(diff.added, [4: "r"])
        XCTAssertEqual(diff.updated, [2: .unchecked(old: "w", new: "ww")])
        XCTAssertEqual(diff.removed, [3: "e"])
        XCTAssertEqual(diff.unchanged, [1: "q"])
    }
}
