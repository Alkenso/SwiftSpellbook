import SwiftConvenience

import Combine
import XCTest

private struct TestStru: Equatable {
    var val = ""
    var nested = Nested()
    
    struct Nested: Equatable {
        var val1 = 10
        var val2 = true
    }
}

class StoreTests: XCTestCase {
    var cancellables: [AnyCancellable] = []
    
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
        
        store.subscribeReceiveChange { change in
            XCTAssertEqual(change.old, TestStru())
            XCTAssertEqual(change.new, TestStru(val: "", nested: .init(val1: 11, val2: true)))
        }.store(in: &cancellables)
        
        store.update(11, at: \.nested.val1)
        XCTAssertEqual(store.value.nested.val1, 11)
    }
    
    func test_scope() {
        let store = ValueStore(initialValue: TestStru())
        let nestedStore = store.scope(\.nested)
        let valStore = store.scope(\.val)
        
        nestedStore.update(.init(val1: 30, val2: false))
        XCTAssertEqual(nestedStore.value, .init(val1: 30, val2: false))
        XCTAssertEqual(store.nested, .init(val1: 30, val2: false))
        
        valStore.update("qwerty")
        XCTAssertEqual(valStore.value, "qwerty")
        XCTAssertEqual(store.val, "qwerty")
        
        store.update(.init(val: "abc", nested: .init(val1: 5, val2: true)))
        XCTAssertEqual(valStore.value, "abc")
        XCTAssertEqual(nestedStore.value, .init(val1: 5, val2: true))
    }
    
    func test_filter() {
        let store = ValueStore(initialValue: 10)
        store.filters = [
            { -10 < $0 }, { $0 < 20 }, // isIncluded if: -10 < value < 20
        ]
        
        XCTAssertEqual(store.value, 10)
        store.update(15)
        XCTAssertEqual(store.value, 15)
        store.update(25)
        XCTAssertEqual(store.value, 15)
        store.update(-15)
        XCTAssertEqual(store.value, 15)
        store.update(10)
        XCTAssertEqual(store.value, 10)
    }
}
