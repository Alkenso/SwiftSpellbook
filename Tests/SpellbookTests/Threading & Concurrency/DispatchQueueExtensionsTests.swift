import SpellbookFoundation
import SpellbookTestUtils

import Foundation
import XCTest

private struct TestError: Error, Equatable {
    var code: Int
}

private final class NonSendableBox {
    var value: Int = 0
}

private let queueKey = DispatchSpecificKey<Int>()
private let queueMark = 0xB0B

class DispatchQueueExtensionsTests: XCTestCase {
    private let queue = DispatchQueue(label: "DispatchQueueExtensionsTests")
    
    override func setUp() {
        queue.setSpecific(key: queueKey, value: queueMark)
    }
    
    func test_asyncPeriodically() {
        nonisolated(unsafe) var count: Int = 0
        let limit = 5
        let exp = expectation(description: "Repeated action")
        exp.expectedFulfillmentCount = limit
        DispatchQueue.global().asyncPeriodically(interval: 0.01, immediately: true) {
            count += 1
            exp.fulfill()
            return count < limit
        }
        Thread.sleep(forTimeInterval: .testSeconds(0.1))
        XCTAssertEqual(count, limit)
        waitForExpectations()
    }
    
    func test_asyncPeriodically_async() {
        nonisolated(unsafe) var count: Int = 0
        let limit = 5
        let exp = expectation(description: "Repeated action")
        exp.expectedFulfillmentCount = limit
        DispatchQueue.global().asyncPeriodically(interval: 0.01, immediately: true) {
            count += 1
            exp.fulfill()
            if count < limit {
                $0()
            }
        }
        Thread.sleep(forTimeInterval: .testSeconds(0.1))
        XCTAssertEqual(count, limit)
        waitForExpectations()
    }
    
    func test_wrapSync() {
        let sum = queue.wrapSync { (lhs: Int, rhs: Int) in
            XCTAssertEqual(DispatchQueue.getSpecific(key: queueKey), queueMark)
            return lhs + rhs
        }
        XCTAssertEqual(sum(10, 20), 30)
        XCTAssertNil(DispatchQueue.getSpecific(key: queueKey))
    }
    
    func test_wrapSync_noArguments() {
        let value = queue.wrapSync { 10 }
        XCTAssertEqual(value(), 10)
    }
    
    func test_wrapSync_throws() {
        let throwing = queue.wrapSync { (code: Int) throws(TestError) -> Int in
            guard code == 0 else { throw TestError(code: code) }
            return code
        }
        XCTAssertEqual(try throwing(0), 0)
        do throws(TestError) {
            _ = try throwing(10)
            XCTFail("Error expected")
        } catch {
            XCTAssertEqual(error, TestError(code: 10))
        }
    }
    
    func test_wrapAsync() {
        let exp = expectation(description: "Async action")
        let action = queue.wrapAsync { (name: String, count: Int) in
            XCTAssertEqual(DispatchQueue.getSpecific(key: queueKey), queueMark)
            XCTAssertEqual(name, "test")
            XCTAssertEqual(count, 10)
            exp.fulfill()
        }
        action("test", 10)
        waitForExpectations()
    }
    
    func test_asyncSending() {
        let exp = expectation(description: "Async action")
        let box = NonSendableBox()
        queue.asyncSending {
            XCTAssertEqual(DispatchQueue.getSpecific(key: queueKey), queueMark)
            box.value += 1
            XCTAssertEqual(box.value, 1)
            exp.fulfill()
        }
        waitForExpectations()
    }
}
