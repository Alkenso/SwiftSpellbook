import SpellbookFoundation

import XCTest

class OtherCommonTests: XCTestCase {
    func test_isXCTest() {
        XCTAssertTrue(RunEnvironment.isXCTesting)
    }
}
