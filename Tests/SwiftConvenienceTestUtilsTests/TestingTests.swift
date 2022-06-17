import SwiftConvenienceTestUtils

import XCTest

class TestingTests: XCTestCase {
    func test_web() {
        XCTAssertEqual(
            Testing.Web.url,
            URL(string: "\(Testing.Web.urlScheme)://\(Testing.Web.urlHost)\(Testing.Web.urlPath)")
        )
    }
    
    func test_files() {
        XCTAssertEqual(Testing.Files.url(1), Testing.Files.url(1))
        XCTAssertNotEqual(Testing.Files.url(1), Testing.Files.url(2))
    }
}
