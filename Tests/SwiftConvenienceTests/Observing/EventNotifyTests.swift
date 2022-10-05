import SwiftConvenience

import XCTest

class EventNotifyTests: XCTestCase {
    func test_receiveValue() {
        let event = EventNotify<Int>()
        var subscriptions: [SubscriptionToken] = []
        defer { withExtendedLifetime(subscriptions) {} }
        
        var expectedValues = [10, 20, 30]
        
        let expectation = expectation(description: "notify called")
        expectation.expectedFulfillmentCount = expectedValues.count
        
        event.subscribe {
            guard !expectedValues.isEmpty else {
                XCTFail("Excepted values empty")
                return
            }
            XCTAssertEqual($0, expectedValues.removeFirst())
            expectation.fulfill()
        }.store(in: &subscriptions)
        
        for value in expectedValues {
            event.notify(value)
        }
        
        waitForExpectations()
    }
    
    func test_receiveValue_initialValue() {
        let event = EventNotify<Int>(initialValue: 0)
        var subscriptions: [SubscriptionToken] = []
        defer { withExtendedLifetime(subscriptions) {} }
        
        let testValues = [10, 20, 30]
        var expectedValues = [0] + testValues // include `initialValue`.
        
        let expectation = expectation(description: "notify called")
        expectation.expectedFulfillmentCount = expectedValues.count
        
        event.subscribe {
            guard !expectedValues.isEmpty else {
                XCTFail("Excepted values empty")
                return
            }
            XCTAssertEqual($0, expectedValues.removeFirst())
            expectation.fulfill()
        }.store(in: &subscriptions)
        
        for value in testValues {
            event.notify(value)
        }
        
        waitForExpectations()
    }
}
