import SpellbookFoundation

import Testing

@Suite
struct AsyncSerialDispatchQueueTests {
    private enum ExpectedError: Error, Equatable {
        case failure(Int)
    }

    @Test @MainActor
    func asyncRunsInSubmissionOrder() async {
        let queue = AsyncSerialDispatchQueue()
        var values: [Int] = []

        queue.async {
            values.append(1)
            await Task.yield()
            values.append(2)
        }
        queue.async {
            values.append(3)
        }
        await queue.sync {}

        #expect(values == [1, 2, 3])
    }

    @Test(arguments: [false, true])
    func concurrentSync(suspends: Bool) async {
        let queue = AsyncSerialDispatchQueue()

        await withTaskGroup { group in
            for input in 0..<16 {
                group.addTask {
                    for _ in 0..<1_000 {
                        let value = await queue.sync {
                            if suspends { await Task.yield() }
                            return input
                        }
                        #expect(value == input)
                    }
                }
            }
        }
    }

    @Test(arguments: [false, true])
    func concurrentSyncFailure(suspends: Bool) async {
        let queue = AsyncSerialDispatchQueue()

        await withTaskGroup(of: Void.self) { group in
            for input in 0..<16 {
                group.addTask {
                    for _ in 0..<1_000 {
                        do {
                            try await queue.sync {
                                if suspends { await Task.yield() }
                                throw ExpectedError.failure(input)
                            }
                            Issue.record("Expected the operation to throw")
                        } catch {
                            #expect(error as? ExpectedError == .failure(input))
                        }
                    }
                }
            }
        }
    }

    @Test
    func syncAcceptsInoutCapture() async {
        func increment(_ value: inout Int, on queue: AsyncSerialDispatchQueue) async {
            await queue.sync {
                await Task.yield()
                value += 1
            }
        }

        var value = 41
        await increment(&value, on: AsyncSerialDispatchQueue())
        #expect(value == 42)
    }
}
