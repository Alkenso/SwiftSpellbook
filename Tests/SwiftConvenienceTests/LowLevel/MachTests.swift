@testable import SwiftConvenience

import XCTest

class MachTests: XCTestCase {
    private let ticksAccuracy: UInt64 = 200
    
    func test_machTime() {
        let currentMach = mach_absolute_time()
        let calculated = Date().machTime!
        XCTAssertLessThanOrEqual(calculated - currentMach, ticksAccuracy)
        
        let currentDate = Date(machTime: mach_absolute_time())!
        XCTAssertEqual(currentDate.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.001)
    }
}
