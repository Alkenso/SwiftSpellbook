import SwiftConvenience

import XCTest

class ArrayTests: XCTestCase {
    func test_mutateElements() {
        XCTAssertEqual([10, 20, 30].mutatingMap { $0 += 5 }, [15, 25, 35])
        
        var arr = [10, 20, 30]
        arr.mutateElements { $0 += 5 }
        XCTAssertEqual(arr, [15, 25, 35])
    }
    
    func test_appending() {
        XCTAssertEqual([].appending(10), [10])
        XCTAssertEqual([10, 20].appending(10), [10, 20, 10])
    }
    
    func test_subscript_safe() {
        XCTAssertEqual([Int]()[safe: 0], nil)
        XCTAssertEqual([10][safe: 0], 10)
        XCTAssertEqual([10][safe: 1], nil)
    }
}
