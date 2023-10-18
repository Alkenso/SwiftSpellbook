@testable import SpellbookFoundation

import XCTest

class GUITests: XCTestCase {
    func test_CGRect_center() {
        XCTAssertEqual(
            CGRect(x: 20, y: 40, width: 100, height: 200)
                .centered(against: CGRect(x: 60, y: 80, width: 400, height: 600)),
            CGRect(x: 210, y: 280, width: 100, height: 200)
        )
        
        XCTAssertEqual(
            CGRect(x: 20, y: 40, width: 400, height: 600)
                .centered(against: CGRect(x: 60, y: 80, width: 100, height: 200)),
            CGRect(x: -90, y: -120, width: 400, height: 600)
        )
    }
    
    func test_CGRect_invertCoordinates() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        XCTAssertEqual(rect.invertCoordinates(height: 1000).invertCoordinates(height: 1000), rect)
        
        XCTAssertEqual(
            CGRect(x: 100, y: 200, width: 150, height: 250).invertCoordinates(height: 1000),
            CGRect(x: 100, y: 550, width: 150, height: 250))
        XCTAssertEqual(
            CGRect(x: 100, y: -200, width: 150, height: 250).invertCoordinates(height: 1000),
            CGRect(x: 100, y: 950, width: 150, height: 250))
    }
}
