import SwiftConvenience

import XCTest

class EventNotifyTests: XCTestCase {
    func test_receiveValue() {
        let event = EventNotify<Int>()
        var subscriptions: [SubscriptionToken] = []
        defer { withExtendedLifetime(subscriptions) {} }
        
        var expectedValues = [10, 20, 30]
        
        let exp = expectation(description: "notify called")
        exp.expectedFulfillmentCount = expectedValues.count
        
        event.subscribe(initialNotify: true) {
            XCTAssertEqual($0, expectedValues.popFirst())
            exp.fulfill()
        }.store(in: &subscriptions)
        
        /// No matter of `initialNotify` value, if `initialValue` not provided,
        /// `receiveValue` is called only on value update.
        let exp2 = expectation(description: "notify called 2")
        exp2.expectedFulfillmentCount = expectedValues.count
        event.subscribe(initialNotify: false) { _ in
            exp2.fulfill()
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
        
        let exp = expectation(description: "notify called")
        exp.expectedFulfillmentCount = expectedValues.count
        
        event.subscribe(initialNotify: true) {
            XCTAssertEqual($0, expectedValues.popFirst())
            exp.fulfill()
        }.store(in: &subscriptions)
        
        /// Because `initialValue` is provided, number of `receiveValue` calls depends on
        /// `initialNotify` parameter.
        let exp2 = expectation(description: "notify called 2")
        exp2.expectedFulfillmentCount = testValues.count
        event.subscribe(initialNotify: false) { _ in
            exp2.fulfill()
        }.store(in: &subscriptions)
        
        for value in testValues {
            event.notify(value)
        }
        
        waitForExpectations()
    }
}
