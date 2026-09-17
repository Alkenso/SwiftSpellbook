import SpellbookFoundation
import SpellbookTestUtils

import CoreFoundation
import Darwin
import Foundation
import XCTest

final class RunLoopSemaphoreTests: XCTestCase {
    func test_waitTimesOutWhenNotSignaled() {
        let semaphore = RunLoopSemaphore()
        
        XCTAssertEqual(semaphore.wait(timeout: .now()), .timedOut)
    }
    
    func test_waitReturnsWhenAlreadySignaled() {
        let semaphore = RunLoopSemaphore()
        let wait: () -> Void = semaphore.wait
        semaphore.signal()
        
        wait()
    }
    
    func test_timedWaitSucceedsWhenAlreadySignaled() {
        let semaphore = RunLoopSemaphore()
        semaphore.signal()
        
        XCTAssertEqual(semaphore.wait(timeout: .now()), .success)
        XCTAssertEqual(semaphore.wait(timeout: .now()), .success)
    }
    
    func test_signalWakesTimedWait() {
        let semaphore = RunLoopSemaphore()
        
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: .testSeconds(0.01))
            semaphore.signal()
        }
        
        XCTAssertEqual(semaphore.wait(timeout: .now() + .testSeconds(0.5)), .success)
    }
    
    func test_signalAfterTimeoutDoesNotStopUnrelatedRunLoop() {
        let semaphore = RunLoopSemaphore()
        XCTAssertEqual(semaphore.wait(timeout: .now()), .timedOut)
        Timer.scheduledTimer(withTimeInterval: .testSeconds(0.01), repeats: false) { _ in
            semaphore.signal()
        }
        
        let result = CFRunLoopRunInMode(.defaultMode, .testSeconds(0.05), false)
        
        XCTAssertEqual(result, .timedOut)
    }
    
    func test_repeatedSignalWakesActiveWait() {
        let semaphore = RunLoopSemaphore()
        let blockerStarted = DispatchSemaphore(value: 0)
        let signalsSent = DispatchSemaphore(value: 0)
        RunLoop.current.perform {
            blockerStarted.signal()
            signalsSent.wait()
        }
        DispatchQueue.global().async {
            blockerStarted.wait()
            semaphore.signal()
            semaphore.signal()
            signalsSent.signal()
        }
        
        let start = DispatchTime.now()
        let timeout = TimeInterval.testSeconds(0.2)
        XCTAssertEqual(semaphore.wait(timeout: .now() + timeout), .success)
        
        let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        XCTAssertLessThan(elapsed, UInt64(TimeInterval(NSEC_PER_SEC) * (timeout / 2)))
    }
}
