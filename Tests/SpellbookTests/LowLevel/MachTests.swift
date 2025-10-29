@testable import SpellbookFoundation
import SpellbookTestUtils

import XCTest

class MachTests: XCTestCase {
    private let ticksAccuracy: UInt64 = UInt64(Double(700) * XCTestCase.waitRate)
    
    func test_machTime() throws {
        let currentMach = mach_absolute_time()
        let calculated = try XCTUnwrap(Date().machTime)
        XCTAssertLessThanOrEqual(calculated - currentMach, ticksAccuracy)
        
        let currentDate = try XCTUnwrap(Date(machTime: mach_absolute_time()))
        XCTAssertEqual(currentDate.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.001)
    }
}
