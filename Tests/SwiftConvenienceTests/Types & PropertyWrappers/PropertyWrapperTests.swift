import SwiftConvenience

import Foundation

import XCTest

class PropertyWrapperTests: XCTestCase {
    func test_clamping() {
        @Clamping(0 ... 10) var a = 15
        XCTAssertEqual(a, 10)
        
        a = 0
        XCTAssertEqual(a, 0)
        
        a = -5
        XCTAssertEqual(a, 0)
        
        a = 3
        XCTAssertEqual(a, 3)
    }
}
