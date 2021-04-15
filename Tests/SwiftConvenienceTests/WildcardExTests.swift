import SwiftConvenience

import XCTest


class WildcardExTests: XCTestCase {
    func test_WildcardEx() throws {
        XCTAssertTrue(WildcardEx(pattern: "").match(""))
        XCTAssertTrue(WildcardEx(pattern: "qwerty").match("qwerty"))
        XCTAssertTrue(WildcardEx(pattern: "q*y").match("qwerty"))
        XCTAssertTrue(WildcardEx(pattern: "qwe?ty").match("qwerty"))
        XCTAssertTrue(WildcardEx(pattern: "/path/to/*/file").match("/path/to/some/file"))
    }
}
