import SwiftConvenience

import XCTest


class WildcardExpressionTests: XCTestCase {
    func test_WildcardExpression() throws {
        XCTAssertTrue(WildcardExpression(pattern: "").match(""))
        XCTAssertTrue(WildcardExpression(pattern: "qwerty").match("qwerty"))
        XCTAssertTrue(WildcardExpression(pattern: "q*y").match("qwerty"))
        XCTAssertTrue(WildcardExpression(pattern: "qwe?ty").match("qwerty"))
        XCTAssertTrue(WildcardExpression(pattern: "/path/to/*/file").match("/path/to/some/file"))
    }
}
