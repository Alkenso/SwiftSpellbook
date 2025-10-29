import SpellbookFoundation

import XCTest

class UtilsTests: XCTestCase {
    func test_updateValue() {
        struct Foo {
            var value = 10
        }
        XCTAssertEqual(updateValue(Foo(), at: \.value, with: 20).value, 20)
        XCTAssertEqual(updateValue(Foo(), using: { $0.value = 20 }).value, 20)
        XCTAssertEqual(updateValue(Foo(), using: { $0 = .init(value: 20) }).value, 20)
     }
}
