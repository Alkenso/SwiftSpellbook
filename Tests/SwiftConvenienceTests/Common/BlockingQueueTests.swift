import SwiftConvenience

import XCTest

class BlockingQueueTests: XCTestCase {
    func test_enqueue_dequeue() throws {
        let queue = BlockingQueue<Int>()
        
        queue.enqueue(10)
        queue.enqueue(20)
        queue.enqueue(30)
        
        XCTAssertEqual(queue.dequeue(), 10)
        XCTAssertEqual(queue.dequeue(), 20)
        XCTAssertEqual(queue.dequeue(), 30)
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
