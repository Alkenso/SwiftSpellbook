import SwiftConvenience

import Combine
import XCTest


class ObservableTests: XCTestCase {
    func test() {
        var values = [10, 20]
        let subscriptionMap = SubscriptionMap<Change<Int>>()
        let observable = Observable<Int>(
            valueRef: .init { !values.isEmpty ? values.removeFirst() : -1 },
            subscribe: subscriptionMap.subscribe
        )
        XCTAssertEqual(observable.value, 10)
        
        var cancellables: [AnyCancellable] = []
        defer { withExtendedLifetime(cancellables) {} }
        
        let exp = expectation(description: "OnChange called")
        
        observable.subscribe { change in
            XCTAssertEqual(change.old, 10)
            XCTAssertEqual(change.new, 20)
            
            XCTAssertEqual(observable.value, 20)
            exp.fulfill()
        }.store(in: &cancellables)
        
        subscriptionMap.notify(.init(old: 10, new: 20))
        
        waitForExpectations()
    }
    
    func test_map() {
        let subscriptionMap = SubscriptionMap<Change<Int>>()
        let observable = Observable<Int>(
            valueRef: .init { 10 },
            subscribe: subscriptionMap.subscribe
        )
        
        var cancellables: [AnyCancellable] = []
        defer { withExtendedLifetime(cancellables) {} }
        
        let exp = expectation(description: "OnChange called")
        exp.expectedFulfillmentCount = 3
        
        observable.subscribe { change in
            XCTAssertEqual(change.old, 10)
            XCTAssertEqual(change.new, 200)
            exp.fulfill()
        }.store(in: &cancellables)
        
        let stringObservable = observable.map(String.init)
        stringObservable.subscribe { change in
            XCTAssertEqual(change.old, "10")
            XCTAssertEqual(change.new, "200")
            exp.fulfill()
        }.store(in: &cancellables)
        
        let countObservable = stringObservable.map(\.count)
        countObservable.subscribe { change in
            XCTAssertEqual(change.old, 2)
            XCTAssertEqual(change.new, 3)
            exp.fulfill()
        }.store(in: &cancellables)
        
        subscriptionMap.notify(.init(old: 10, new: 200))
        
        waitForExpectations()
    }
}
