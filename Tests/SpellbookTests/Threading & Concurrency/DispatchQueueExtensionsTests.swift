import SpellbookFoundation
import SpellbookTestUtils

import Foundation
import XCTest

class DispatchQueueExtensionsTests: XCTestCase {
    func test_asyncPeriodically() {
        var count: Int = 0
        let limit = 5
        let exp = expectation(description: "Repeated action")
        exp.expectedFulfillmentCount = limit
        DispatchQueue.global().asyncPeriodically(interval: 0.01, immediately: true) {
            count += 1
            exp.fulfill()
            return count < limit
        }
        Thread.sleep(forTimeInterval: 0.1 * Self.waitRate)
        XCTAssertEqual(count, limit)
        waitForExpectations()
    }
}
