import SpellbookFoundation

import Testing

@Suite
struct AsyncFutureTests {
    @Test
    func firstValueIsPreserved() async {
        let promise = AsyncPromise<Int>()
        #expect(promise.set(42))
        #expect(!promise.set(99))

        #expect(await promise.future.get() == 42)
        #expect(await promise.future.get() == 42)
    }

    @Test
    func nilIsAResolvedValue() async {
        let promise = AsyncPromise<Int?>()

        #expect(promise.set(nil))
        #expect(!promise.set(42))
        #expect(await promise.get() == nil)
    }

    @Test
    func concurrentReadersReceiveTheWinningValue() async {
        let promise = AsyncPromise<Int>()
        let future = promise.future

        await withTaskGroup(of: Int?.self) { group in
            for _ in 0..<16 {
                group.addTask {
                    #expect(await future.get() == 42)
                    return nil
                }
            }
            for _ in 0..<16 {
                group.addTask {
                    promise.set(42) ? 1 : 0
                }
            }

            var resolutionCount = 0
            for await result in group {
                resolutionCount += result ?? 0
            }
            #expect(resolutionCount == 1)
        }
    }
}
