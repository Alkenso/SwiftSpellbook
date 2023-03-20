import SwiftConvenience

import XCTest

class UtilsTests: XCTestCase {
    func test_updateSwap() {
        var a = 10
        XCTAssertEqual(updateSwap(&a, 20), 10)
        XCTAssertEqual(a, 20)
    }
}
