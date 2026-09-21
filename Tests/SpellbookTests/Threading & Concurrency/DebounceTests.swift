import SpellbookFoundation
import SpellbookTestUtils

import Foundation
import XCTest

class DebounceTests: XCTestCase {
    func test_debounce() {
        let context = DebounceContext(delay: .testSeconds(0.05))
        let queue = DispatchQueue(label: "DebounceTests")
        let counter = Atomic(wrappedValue: 0)
        let exp = expectation(description: "Debounced action")
        
        for _ in 0..<5 {
            queue.debounce(with: context) {
                counter.increment(by: 1)
                exp.fulfill()
            }
        }
        
        waitForExpectations()
        XCTAssertEqual(counter.wrappedValue, 1)
    }
    
    func test_debounce_cancel() {
        let context = DebounceContext(delay: .testSeconds(0.05))
        let queue = DispatchQueue(label: "DebounceTests")
        let counter = Atomic(wrappedValue: 0)
        
        queue.debounce(with: context) { counter.increment(by: 1) }
        context.cancel()
        
        Thread.sleep(forTimeInterval: .testSeconds(0.1))
        XCTAssertEqual(counter.wrappedValue, 0)
    }
    
    func test_asyncDebounce() async throws {
        let context = DebounceContext(delay: .testSeconds(0.05))
        let counter = Atomic(wrappedValue: 0)
        let exp = expectation(description: "Debounced operation")
        
        for _ in 0..<5 {
            context.schedule {
                counter.increment(by: 1)
                exp.fulfill()
            }
        }
        
        await fulfillment(of: [exp], timeout: .testSeconds(XCTestCase.waitTimeout))
        XCTAssertEqual(counter.wrappedValue, 1)
    }
    
    func test_asyncDebounce_cancel() async throws {
        let context = DebounceContext(delay: .testSeconds(0.05))
        let counter = Atomic(wrappedValue: 0)
        
        context.schedule { counter.increment(by: 1) }
        context.cancel()
        
        try await Task.sleep(for: .timeInterval(.testSeconds(0.1)))
        XCTAssertEqual(counter.wrappedValue, 0)
    }
    
    func test_debounce_mixed() async throws {
        let context = DebounceContext(delay: .testSeconds(0.05))
        let queue = DispatchQueue(label: "DebounceTests")
        let queueCounter = Atomic(wrappedValue: 0)
        let asyncCounter = Atomic(wrappedValue: 0)
        let exp = expectation(description: "Debounced operation")
        
        queue.debounce(with: context) { queueCounter.increment(by: 1) }
        context.schedule {
            asyncCounter.increment(by: 1)
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: .testSeconds(XCTestCase.waitTimeout))
        try await Task.sleep(for: .timeInterval(.testSeconds(0.1)))
        XCTAssertEqual(queueCounter.wrappedValue, 0)
        XCTAssertEqual(asyncCounter.wrappedValue, 1)
    }
}
