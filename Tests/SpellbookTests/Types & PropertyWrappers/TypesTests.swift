import SpellbookFoundation
import SpellbookTestUtils
import XCTest

class TypesTests: XCTestCase {
    func test_ProgressValue() {
        var value = ProgressValue(current: 1, total: 5)
        XCTAssertEqual(value.ratio, 0.2)
        
        value.increment()
        XCTAssertEqual(value.current, 2)
        XCTAssertEqual(value.total, 5)
        
        value.increment(by: 10)
        XCTAssertEqual(value.current, 5)
        XCTAssertEqual(value.total, 5)
        
        value.increment(by: 5, unsafe: true)
        XCTAssertEqual(value.current, 10)
        XCTAssertEqual(value.total, 5)
        XCTAssertEqual(value.ratio, 1)
        XCTAssertEqual(value.unsafeRatio, 2)
        
        value.increment(by: -15)
        XCTAssertEqual(value.current, 0)
        XCTAssertEqual(value.total, 5)
        
        value.increment(by: -5, unsafe: true)
        XCTAssertEqual(value.current, -5)
        XCTAssertEqual(value.total, 5)
    }
}
