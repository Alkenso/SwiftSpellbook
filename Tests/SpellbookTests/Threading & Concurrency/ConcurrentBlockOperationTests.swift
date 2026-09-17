import SpellbookFoundation
import SpellbookTestUtils

import Foundation
import XCTest

private final class OperationStateObserver: NSObject, @unchecked Sendable {
    let values = Synchronized<[Bool]>(.unfair)

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if let value = change?[.newKey] as? Bool {
            values.append(value)
        }
    }
}

class ConcurrentBlockOperationTests: XCTestCase {
    func test() throws {
        let interval = 0.1
        let op = ConcurrentBlockOperation { isCancelled, completion in
            Thread.sleep(forTimeInterval: .testSeconds(interval))
            completion()
        }
        let queue = OperationQueue()
        queue.addOperation(op)
        
        Thread.sleep(forTimeInterval: .testSeconds(0.05))
        
        XCTAssertTrue(op.isAsynchronous)
        XCTAssertTrue(op.isReady)
        XCTAssertTrue(op.isExecuting)
        XCTAssertFalse(op.isFinished)
        
        Thread.sleep(forTimeInterval: .testSeconds(interval))
        
        XCTAssertFalse(op.isExecuting)
        XCTAssertTrue(op.isFinished)
    }
    
    func test_cancel() throws {
        let exp = expectation(description: "finished")
        let op = ConcurrentBlockOperation { isCancelled, completion in
            while !isCancelled.value {
                Thread.sleep(forTimeInterval: .testSeconds(0.01))
            }
            completion()
            exp.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(op)
        
        DispatchQueue.global().asyncAfter(delay: .testSeconds(0.1)) {
            op.cancel()
        }
        
        waitForExpectations(timeout: 0.2)
    }

    func test_multipleCompletions() {
        let op = ConcurrentBlockOperation { _, completion in
            completion()
            completion()
        }
        let executingObserver = OperationStateObserver()
        let finishedObserver = OperationStateObserver()
        op.addObserver(executingObserver, forKeyPath: "isExecuting", options: .new, context: nil)
        op.addObserver(finishedObserver, forKeyPath: "isFinished", options: .new, context: nil)
        defer {
            op.removeObserver(executingObserver, forKeyPath: "isExecuting")
            op.removeObserver(finishedObserver, forKeyPath: "isFinished")
        }

        let queue = OperationQueue()
        queue.addOperations([op], waitUntilFinished: true)

        XCTAssertEqual(executingObserver.values.read(), [true, false])
        XCTAssertEqual(finishedObserver.values.read(), [true])
    }
}
