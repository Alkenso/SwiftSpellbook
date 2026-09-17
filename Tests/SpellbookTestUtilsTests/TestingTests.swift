import SpellbookTestUtils

import XCTest

class TestingTests: XCTestCase {
    func test_web() {
        XCTAssertEqual(
            TestData.Web.url,
            URL(string: "\(TestData.Web.urlScheme)://\(TestData.Web.urlHost)\(TestData.Web.urlPath)")
        )
    }
    
    func test_files() {
        XCTAssertEqual(TestData.Files.url(1), TestData.Files.url(1))
        XCTAssertNotEqual(TestData.Files.url(1), TestData.Files.url(2))
    }
}
