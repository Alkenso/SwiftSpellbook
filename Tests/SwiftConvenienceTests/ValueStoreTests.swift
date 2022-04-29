import SwiftConvenience
import SwiftConvenienceTestUtils

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
        store.subscribe { val in
            if initial {
                XCTAssertEqual(val, store.value)
            } else {
                XCTAssertNotEqual(val, store.value)
            }
            initial = false
        }.store(in: &cancellables)
        
        let updateValue = TestStru(val: "q", nested: TestStru.Nested(val1: 11, val2: true))
        store.subscribeChange { change in
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
    
    func test_context() {
        let initialValue = Pair<Int, String>(10, "qq")
        let store = ValueStore(initialValue: initialValue)
        let intStore = store.scope(\.first)
        let stringStore = store.scope(\.second)
        
        let storeExp = expectation(description: "On value received - store")
        storeExp.expectedFulfillmentCount = 4 // 3 updates + initial value
        let contextObject = Data(pod: 123)
        store.subscribe { value, context in
            if value == initialValue {
                XCTAssertNil(context)
            } else {
                XCTAssertEqual(context as? Data, contextObject)
            }
            storeExp.fulfill()
        }.store(in: &cancellables)
        
        let intStoreExp = expectation(description: "On value received - intStore")
        intStoreExp.expectedFulfillmentCount = 4 // 2 updates + 1 same value + initial value
        intStore.subscribe { value, context in
            if value == initialValue.first {
                XCTAssertNil(context)
            } else {
                XCTAssertEqual(context as? Data, contextObject)
            }
            intStoreExp.fulfill()
        }.store(in: &cancellables)
        
        let stringStoreExp = expectation(description: "On value received - stringStore")
        stringStoreExp.expectedFulfillmentCount = 4 // 2 updates + 1 same value + initial value
        stringStore.subscribe { value, context in
            if value == initialValue.second {
                XCTAssertNil(context)
            } else {
                XCTAssertEqual(context as? Data, contextObject)
            }
            stringStoreExp.fulfill()
        }.store(in: &cancellables)
        
        store.update(.init(20, "ww"), context: contextObject)
        intStore.update(30, context: contextObject)
        stringStore.update("ee", context: contextObject)
        
        waitForExpectations()
    }
    
    func test_recursiveUpdate() {
        let store = ValueStore<Int>(initialValue: 0)
        let exp = expectation(description: "Recursive store calls")
        exp.expectedFulfillmentCount = 3
        store.subscribe { value in
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
