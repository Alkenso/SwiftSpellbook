import SwiftConvenience

import Combine
import XCTest

class ObservableTests: XCTestCase {
    func test() {
        var value = 10
        let event = EventNotify<Int>()
        let observable = Observable<Int>(
            valueRef: .init { value },
            subscribeReceiveValue: {
                let token = event.subscribe(receiveValue: $0)
                $0(value, nil)
                return token
            }
        )
        XCTAssertEqual(observable.value, 10)
        
        var cancellables: [AnyCancellable] = []
        defer { withExtendedLifetime(cancellables) {} }
        
        let exp = expectation(description: "OnChange called")
        
        observable.subscribeChange { change in
            XCTAssertEqual(change.old, 10)
            XCTAssertEqual(change.new, 20)
            
            XCTAssertEqual(observable.value, 20)
            exp.fulfill()
        }.store(in: &cancellables)
        
        value = 20
        event.notify(20)
        
        waitForExpectations()
    }
    
    func test_scope() {
        var value = 10
        let event = EventNotify<Int>()
        let observable = Observable<Int>(
            valueRef: .init { value },
            subscribeReceiveValue: {
                let token = event.subscribe(receiveValue: $0)
                $0(value, nil)
                return token
            }
        )
        
        var cancellables: [AnyCancellable] = []
        defer { withExtendedLifetime(cancellables) {} }
        
        let exp = expectation(description: "OnChange called")
        exp.expectedFulfillmentCount = 4
        
        observable.subscribeChange { change in
            XCTAssertEqual(change.old, 10)
            XCTAssertEqual(change.new, 200)
            exp.fulfill()
        }.store(in: &cancellables)
        
        let stringObservable = observable.scope(String.init)
        stringObservable.subscribeChange { change in
            XCTAssertEqual(change.old, "10")
            XCTAssertEqual(change.new, "200")
            exp.fulfill()
        }.store(in: &cancellables)
        
        let countObservable = stringObservable.scope(\.count)
        countObservable.subscribeChange { change in
            XCTAssertEqual(change.old, 2)
            XCTAssertEqual(change.new, 3)
            exp.fulfill()
        }.store(in: &cancellables)
        
        // anonymous.
        stringObservable.scope(\.count).subscribeChange { change in
            XCTAssertEqual(change.old, 2)
            XCTAssertEqual(change.new, 3)
            exp.fulfill()
        }.store(in: &cancellables)
        
        value = 200
        event.notify(200)
        
        waitForExpectations()
    }
}
