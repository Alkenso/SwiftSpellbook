import SpellbookFoundation

import XCTest

class BlockingQueueTests: XCTestCase {
    func test_enqueue_dequeue() throws {
        let queue = BlockingQueue<Int>()
        
        queue.enqueue(10)
        XCTAssertEqual(queue.approximateCount, 1)
        queue.enqueue(20)
        XCTAssertEqual(queue.approximateCount, 2)
        queue.enqueue(30)
        XCTAssertEqual(queue.approximateCount, 3)
        
        XCTAssertEqual(queue.dequeue(), 10)
        XCTAssertEqual(queue.approximateCount, 2)
        XCTAssertEqual(queue.dequeue(), 20)
        XCTAssertEqual(queue.approximateCount, 1)
        XCTAssertEqual(queue.dequeue(), 30)
        XCTAssertEqual(queue.approximateCount, 0)
    }
    
    func test_blocking() throws {
        let queue = BlockingQueue<Int>()
        
        let beforeDequeueExp = expectation(description: "before dequeue")
        @Indirect var dequeueExp = expectation(description: "should not be dequeued")
        dequeueExp.isInverted = true
        DispatchQueue.global().async {
            beforeDequeueExp.fulfill()
            XCTAssertEqual(queue.dequeue(), 10)
            dequeueExp.fulfill()
        }
        waitForExpectations(timeout: 0.1, ignoreWaitRate: true)
        
        dequeueExp = expectation(description: "dequeued after enqueue")
        queue.enqueue(10)
        
        waitForExpectations()
    }
    
    func test_invalidate() throws {
        let emptyQueue = BlockingQueue<Int>()
        emptyQueue.invalidate()
        XCTAssertNil(emptyQueue.dequeue())
        
        let queue = BlockingQueue<Int>()
        queue.enqueue(10)
        queue.enqueue(20)
        queue.enqueue(30)
        
        queue.invalidate()
        
        XCTAssertNil(emptyQueue.dequeue())
    }
    
    func test_invalidate_noRemoval() throws {
        let queue = BlockingQueue<Int>()
        queue.enqueue(10)
        queue.enqueue(20)
        queue.enqueue(30)
        
        queue.invalidate(removeAll: false)
        
        XCTAssertEqual(queue.dequeue(), 10)
        XCTAssertEqual(queue.dequeue(), 20)
        XCTAssertEqual(queue.dequeue(), 30)
        XCTAssertNil(queue.dequeue())
    }
    
    func test_cancel() throws {
        let queue = BlockingQueue<Int>()
        
        queue.enqueue(10)
        queue.enqueue(20)
        queue.enqueue(30)
        
        var isCancelled = false
        XCTAssertEqual(queue.dequeue(isCancelled: &isCancelled), 10)
        XCTAssertEqual(isCancelled, false)
        
        queue.cancel()
        
        XCTAssertEqual(queue.dequeue(isCancelled: &isCancelled), 20)
        XCTAssertEqual(isCancelled, true)
        
        XCTAssertEqual(queue.dequeue(), 30)
    }
}
