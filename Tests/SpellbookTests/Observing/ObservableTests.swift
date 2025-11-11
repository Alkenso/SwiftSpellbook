import SpellbookFoundation
import SpellbookTestUtils

import Combine
import XCTest

class ObservableTests: XCTestCase {
    var cancellables: [AnyCancellable] = []
    
    override func setUp() {
        cancellables.removeAll()
    }
    
    func test() {
        nonisolated(unsafe) var value = 10
        let event = EventNotify<Int>()
        let observable = ValueObservable<Int>(
            view: .init { value },
            subscribeReceiveValue: {
                let token = event.subscribe(receiveValue: $1)
                $1(value, nil)
                return token
            }
        )
        XCTAssertEqual(observable.value, 10)
        
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
    
    func test_constant() {
        let observable = ValueObservable<Int>.constant(10)
        nonisolated(unsafe) var value: Int?
        
        observable
            .subscribe(suppressInitialNotify: true) { value = $0 }
            .store(in: &cancellables)
        XCTAssertNil(value)
        
        observable
            .subscribe(suppressInitialNotify: false) { value = $0 }
            .store(in: &cancellables)
        XCTAssertEqual(value, 10)
    }
    
    func test_scope() {
        nonisolated(unsafe) var value = 10
        let event = EventNotify<Int>()
        let observable = ValueObservable<Int>(
            view: .init { value },
            subscribeReceiveValue: {
                let token = event.subscribe(receiveValue: $1)
                $1(value, nil)
                return token
            }
        )
        
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
