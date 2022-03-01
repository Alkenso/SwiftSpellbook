import SwiftConvenience

import Combine
import XCTest

class ObservableTests: XCTestCase {
    func test() {
        var value = 10
        let subscriptionMap = SubscriptionMap<Int>()
        let observable = Observable<Int>(
            valueRef: .init { value },
            subscribeReceiveValue: { subscriptionMap.subscribe(notifyImmediately: value, action: $0) }
        )
        XCTAssertEqual(observable.value, 10)
        
        var cancellables: [AnyCancellable] = []
        defer { withExtendedLifetime(cancellables) {} }
        
        let exp = expectation(description: "OnChange called")
        
        observable.subscribeReceiveChange { change in
            XCTAssertEqual(change.old, 10)
            XCTAssertEqual(change.new, 20)
            
            XCTAssertEqual(observable.value, 20)
            exp.fulfill()
        }.store(in: &cancellables)
        
        value = 20
        subscriptionMap.notify(20)
        
        waitForExpectations()
    }
    
    func test_scope() {
        var value = 10
        let subscriptionMap = SubscriptionMap<Int>()
        let observable = Observable<Int>(
            valueRef: .init { value },
            subscribeReceiveValue: { subscriptionMap.subscribe(notifyImmediately: value, action: $0) }
        )
        
        var cancellables: [AnyCancellable] = []
        defer { withExtendedLifetime(cancellables) {} }
        
        let exp = expectation(description: "OnChange called")
        exp.expectedFulfillmentCount = 3
        
        observable.subscribeReceiveChange { change in
            XCTAssertEqual(change.old, 10)
            XCTAssertEqual(change.new, 200)
            exp.fulfill()
        }.store(in: &cancellables)
        
        let stringObservable = observable.scope(String.init)
        stringObservable.subscribeReceiveChange { change in
            XCTAssertEqual(change.old, "10")
            XCTAssertEqual(change.new, "200")
            exp.fulfill()
        }.store(in: &cancellables)
        
        let countObservable = stringObservable.scope(\.count)
        countObservable.subscribeReceiveChange { change in
            XCTAssertEqual(change.old, 2)
            XCTAssertEqual(change.new, 3)
            exp.fulfill()
        }.store(in: &cancellables)
        
        value = 200
        subscriptionMap.notify(200)
        
        waitForExpectations()
    }
}
