import SpellbookFoundation
import SpellbookTestUtils

import Foundation
import XCTest

class ConcurrentBlockOperationTests: XCTestCase {
    func test() throws {
        let interval = 0.1
        let op = ConcurrentBlockOperation { isCancelled, completion in
            Self.sleep(interval: interval)
            completion()
        }
        let queue = OperationQueue()
        queue.addOperation(op)
        
        Self.sleep(interval: 0.05)
        
        XCTAssertTrue(op.isAsynchronous)
        XCTAssertTrue(op.isReady)
        XCTAssertTrue(op.isExecuting)
        XCTAssertFalse(op.isFinished)
        
        Self.sleep(interval: interval)
        
        XCTAssertFalse(op.isExecuting)
        XCTAssertTrue(op.isFinished)
    }
    
    func test_cancel() throws {
        let exp = expectation(description: "finished")
        let op = ConcurrentBlockOperation { isCancelled, completion in
            while !isCancelled.value {
                Thread.sleep(forTimeInterval: 0.01)
            }
            completion()
            exp.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(op)
        
        DispatchQueue.global().asyncAfter(delay: 0.1) {
            op.cancel()
        }
        
        waitForExpectations(timeout: 0.2)
    }
}
