import SpellbookFoundation

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
            Thread.sleep(forTimeInterval: 0.01)
            semaphore.signal()
        }

        XCTAssertEqual(semaphore.wait(timeout: .now() + 0.5), .success)
    }

    func test_signalAfterTimeoutDoesNotStopUnrelatedRunLoop() {
        let semaphore = RunLoopSemaphore()
        XCTAssertEqual(semaphore.wait(timeout: .now()), .timedOut)
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
            semaphore.signal()
        }

        let result = CFRunLoopRunInMode(.defaultMode, 0.05, false)

        XCTAssertEqual(result, .timedOut)
    }

    func test_repeatedSignalWakesActiveWait() {
        let semaphore = RunLoopSemaphore()
        let blockerStarted = DispatchSemaphore(value: 0)
        let signalsSent = DispatchSemaphore(value: 0)
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) {
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

        XCTAssertEqual(semaphore.wait(timeout: .now() + 0.2), .success)

        let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        XCTAssertLessThan(elapsed, NSEC_PER_SEC / 10)
    }

    @MainActor
    func test_backgroundWaitDoesNotSpin() {
        let completed = expectation(description: "background wait completed")

        DispatchQueue.global().async {
            let semaphore = RunLoopSemaphore()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                semaphore.signal()
            }
            let start = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)

            semaphore.wait()

            let elapsed = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID) - start
            XCTAssertLessThan(elapsed, NSEC_PER_SEC / 50)
            completed.fulfill()
        }

        waitForExpectations(timeout: 0.5)
    }
}
