import SpellbookFoundation
import SpellbookTestUtils

import Testing
import XCTest

@Suite
struct TaskTests {
    @Test
    func after_throwingOperation() async throws {
        let task = Task<Int, Error>.after(.zero) {
            42
        }
        
        let value = try await task.value

        #expect(value == 42)
    }
    
    @Test
    func after_nonThrowingOperation() async {
        let completed = Atomic(wrappedValue: false)
        let task = Task<Void, Never>.after(.zero) {
            completed.wrappedValue = true
        }
        
        await task.value
        
        #expect(completed.wrappedValue)
    }
    
    @Test
    func after_cancelledTaskDoesNotRunOperation() async {
        let operationRan = Atomic(wrappedValue: false)
        let task = Task<Void, Never>.after(.seconds(1)) {
            operationRan.wrappedValue = true
        }
        
        task.cancel()
        await task.value
        
        #expect(!operationRan.wrappedValue)
    }
    
    @Test
    func periodically_waitsBetweenCalls() async {
        let interval = Duration.timeInterval(.testSeconds(0.01))
        let lastCall = Atomic(wrappedValue: ContinuousClock.now)
        let calls = XCTestExpectation(description: "Two periodic calls")
        calls.expectedFulfillmentCount = 2
        
        let task = Task.periodically(every: interval) {
            let now = ContinuousClock.now
            #expect(lastCall.exchange(now).duration(to: now) >= interval)
            calls.fulfill()
        }
        
        let result = await XCTWaiter.fulfillment(of: [calls], timeout: 2)
        task.cancel()
        await task.value
        #expect(result == .completed)
    }
    
    @Test(arguments: [0, 1, 3], [false, true])
    func periodically_respectsMaxCount(maxCount: Int, immediately: Bool) async {
        let calls = Atomic(wrappedValue: 0)
        let task = Task.periodically(every: .zero, immediately: immediately, maxCount: maxCount) {
            calls.increment(by: 1)
        }
        
        await task.value
        
        #expect(calls.wrappedValue == max(1, maxCount))
    }
    
    @Test
    func periodically_runsImmediately() async {
        let firstCall = XCTestExpectation(description: "Immediate call")
        let task = Task.periodically(every: .timeInterval(.testSeconds(60)), immediately: true) {
            firstCall.fulfill()
        }
        
        let result = await XCTWaiter.fulfillment(of: [firstCall], timeout: 2)
        task.cancel()
        await task.value
        #expect(result == .completed)
    }
}
