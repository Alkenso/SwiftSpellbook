import SpellbookFoundation

import Combine
import XCTest

private class ValueWrapper<T>: ValueObserving {
    private var subscriptions: [(suppressInitialNotify: Bool, receiveValue: (T, Any?) -> Void)] = []
    
    init(value: T) {
        self.value = value
    }
    
    var value: T {
        didSet { subscriptions.forEach { $0.receiveValue(value, nil) } }
    }
    
    func subscribe(suppressInitialNotify: Bool, receiveValue: @escaping (T, Any?) -> Void) -> SubscriptionToken {
        subscriptions.append((suppressInitialNotify, receiveValue))
        if !suppressInitialNotify {
            receiveValue(value, nil)
        }
        return .init {}
    }
}

class ValueObservingTests: XCTestCase {
    private var cancellables: [AnyCancellable] = []
    
    override func tearDown() {
        cancellables.removeAll()
    }
    
    func test_receiveValue() {
        let wrapper = ValueStore(initialValue: 10)
        XCTAssertEqual(wrapper.value, 10)
        
        var receivedValue: Int?
        wrapper.subscribe {
            receivedValue = $0
        }.store(in: &cancellables)
        
        XCTAssertEqual(receivedValue, 10)
        
        wrapper.update(20)
        XCTAssertEqual(receivedValue, 20)
        
        wrapper.update(30)
        XCTAssertEqual(receivedValue, 30)
    }
    
    func test_receiveChange() {
        let wrapper = ValueWrapper(value: 10)
        XCTAssertEqual(wrapper.value, 10)
        
        var receivedChange: Change<Int>?
        wrapper.subscribeChange {
            receivedChange = $0
        }.store(in: &cancellables)
        
        XCTAssertEqual(receivedChange, nil)
        
        wrapper.value = 20
        XCTAssertEqual(receivedChange, .unchecked(old: 10, new: 20))
        
        wrapper.value = 30
        XCTAssertEqual(receivedChange, .unchecked(old: 20, new: 30))
    }
    
    func test_publisher() {
        let wrapper = ValueWrapper(value: 10)
        let exp = expectation(description: "Value published")
        wrapper.publisher().sink {
            XCTAssertEqual($0.0, 10)
            exp.fulfill()
        }.store(in: &cancellables)
        
        waitForExpectations()
    }
    
    func test_stream() {
        let wrapper = ValueWrapper(value: 10)
        let exp = expectation(description: "Value async delivered")
        Task {
            for await value in wrapper.stream() {
                XCTAssertEqual(value.0, 10)
                exp.fulfill()
            }
        }.store(in: &cancellables)
        
        waitForExpectations()
    }
    
    func test_stream_suppressInitial() {
        let wrapper = ValueWrapper(value: 10)
        let exp = expectation(description: "Value async delivered")
        let stream = wrapper.stream(suppressInitialNotify: true)
        Task {
            for await value in stream {
                XCTAssertEqual(value.0, 20)
                exp.fulfill()
            }
        }.store(in: &cancellables)
        wrapper.value = 20
        
        waitForExpectations()
    }
    
    func test_stream_suppressInitial_noValue() {
        let wrapper = ValueWrapper(value: 10)
        let exp = expectation(description: "No value async delivered")
        exp.isInverted = true
        let stream = wrapper.stream(suppressInitialNotify: true)
        Task {
            for await _ in stream {
                exp.fulfill()
            }
        }.store(in: &cancellables)
        
        waitForExpectations(timeout: 0.05)
    }
}
