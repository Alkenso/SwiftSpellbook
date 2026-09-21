import SpellbookFoundation

import Testing

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
}
