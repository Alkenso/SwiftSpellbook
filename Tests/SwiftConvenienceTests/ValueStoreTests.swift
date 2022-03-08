import SwiftConvenience

import XCTest

private struct TestStru: Equatable {
    var val = ""
    var nested = Nested()
    
    struct Nested: Equatable {
        var val1 = 0
        var val2 = false
    }
}

class StoreTests: XCTestCase {
    var cancellables: [SubscriptionToken] = []
    
    func test() {
        let store = ValueStore(initialValue: TestStru())
        XCTAssertEqual(store.value, TestStru())
        
        var initial = true
        store.subscribeReceiveValue { val in
            if initial {
                XCTAssertEqual(val, store.value)
            } else {
                XCTAssertNotEqual(val, store.value)
            }
            initial = false
        }.store(in: &cancellables)
        
        let updateValue = TestStru(val: "q", nested: TestStru.Nested(val1: 11, val2: true))
        store.subscribeReceiveChange { change in
            XCTAssertEqual(change.old, TestStru())
            XCTAssertEqual(change.new, updateValue)
        }.store(in: &cancellables)
        
        store.update(updateValue)
        XCTAssertEqual(store.value.nested.val1, 11)
    }
    
    func test_scope() {
        let store = ValueStore(initialValue: TestStru())
        let nestedStore = store.scope(\.nested)
        let valStore = store.scope(\.val)
        let nestedValStore = nestedStore.scope(\.val1)
        
        store.update(TestStru(val: "q", nested: TestStru.Nested(val1: 10, val2: true)))
        XCTAssertEqual(store.value, TestStru(val: "q", nested: TestStru.Nested(val1: 10, val2: true)))
        XCTAssertEqual(nestedStore.value, TestStru.Nested(val1: 10, val2: true))
        XCTAssertEqual(valStore.value, "q")
        XCTAssertEqual(nestedValStore.value, 10)
        
        nestedStore.update(TestStru.Nested(val1: 20, val2: false))
        XCTAssertEqual(store.nested, TestStru.Nested(val1: 20, val2: false))
        XCTAssertEqual(nestedStore.value, TestStru.Nested(val1: 20, val2: false))
        XCTAssertEqual(valStore.value, "q")
        XCTAssertEqual(nestedValStore.value, 20)
        
        valStore.update("qwerty")
        XCTAssertEqual(store.val, "qwerty")
        XCTAssertEqual(valStore.value, "qwerty")
        
        nestedValStore.update(30)
        XCTAssertEqual(store.nested.val1, 30)
        XCTAssertEqual(nestedStore.val1, 30)
        XCTAssertEqual(nestedValStore.value, 30)
    }
    
    func test_recursiveUpdate() {
        let store = ValueStore<Int>(initialValue: 0)
        let exp = expectation(description: "Recursive store calls")
        exp.expectedFulfillmentCount = 3
        store.subscribeReceiveValue { value in
            guard value < 3 else { return }
            if value == 0 {
                XCTAssertEqual(value, store.value)
            } else {
                XCTAssertEqual(value, store.value + 1)
            }
            store.update(value + 1)
            
            exp.fulfill()
        }.store(in: &cancellables)
        
        waitForExpectations()
    }
}
