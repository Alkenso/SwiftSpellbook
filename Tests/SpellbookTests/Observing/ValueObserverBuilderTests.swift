import Foundation
import SpellbookFoundation

import Testing

private actor ValueObserverBuilderGate {
    private var continuations: [Int: CheckedContinuation<Void, Never>] = [:]
    private var released: Set<Int> = []

    func wait(for value: Int) async {
        if released.remove(value) != nil {
            return
        }
        await withCheckedContinuation { continuation in
            continuations[value] = continuation
        }
    }

    func release(_ value: Int) {
        if let continuation = continuations.removeValue(forKey: value) {
            continuation.resume()
        } else {
            released.insert(value)
        }
    }
}

private final class ValueObserverBuilderNonSendableState {
    var values: [Int] = []
    var terminated = false

    private let onDeinit: @Sendable () -> Void

    init(onDeinit: @escaping @Sendable () -> Void = {}) {
        self.onDeinit = onDeinit
    }

    deinit {
        onDeinit()
    }
}

private struct ValueObserverBuilderPayload: Equatable, Sendable {
    var value: Int
}

private struct ValueObserverBuilderState: Sendable {
    var isValid: Bool
    var payload: ValueObserverBuilderPayload?
}

@Suite
struct ValueObserverBuilderTests {
    @Test
    func name_startsPipeline() {
        let observer: ValueObserver<Int> = .name("source").sync { _ in }

        #expect(observer.name == "source")
    }

    @Test
    func name_afterOperator() {
        let observer: ValueObserver<Int> = .map { $0 + 1 }
            .name("mapped")
            .sync { _ in }

        #expect(observer.name == "mapped")
    }

    @Test
    func observe_valueAndTermination() {
        let values = Synchronized<[Int]>(.unfair, [])
        let terminationCount = Synchronized(.unfair, 0)
        let observer = ValueObserver<Int> { value in
            if let value {
                values.write { $0.append(value) }
            } else {
                terminationCount.write { $0 += 1 }
            }
        }

        observer.observe(1)
        observer.observe(nil)

        #expect(values.read() == [1])
        #expect(terminationCount.read() == 1)
    }

    @Test
    func sync_contextualValueType() {
        let values = Synchronized<[Int]>(.unfair, [])
        let observer: ValueObserver<Int> = .sync { value in
            values.write { $0.append(value) }
        }

        observer.observe(1)
        observer.observe(2)
        observer.observe(nil)

        #expect(values.read() == [1, 2])
    }

    @Test
    func operators_orderAndSuppression() {
        let events = Synchronized<[String]>(.unfair, [])
        let observer: ValueObserver<Int> = .map { value in
            events.write { $0.append("map:\(value)") }
            return value + 1
        }
        .filter { value in
            events.write { $0.append("filter:\(value)") }
            return value.isMultiple(of: 2)
        }
        .compactMap { value in
            events.write { $0.append("compactMap:\(value)") }
            return value == 2 ? "value:\(value)" : nil
        }
        .sync(
            onTermination: {
                events.write { $0.append("terminate") }
            },
            { value in
                events.write { $0.append("sync:\(value)") }
            }
        )

        observer.observe(1)
        observer.observe(2)
        observer.observe(3)
        observer.observe(nil)

        #expect(events.read() == [
            "map:1",
            "filter:2",
            "compactMap:2",
            "sync:value:2",
            "map:2",
            "filter:3",
            "map:3",
            "filter:4",
            "compactMap:4",
            "terminate",
        ])
    }

    @Test
    func map_optionalOutputNilIsValue() {
        let values = Synchronized<[Int?]>(.unfair, [])
        let terminationCount = Synchronized(.unfair, 0)
        let observer: ValueObserver<Int> = .map { value -> Int? in
            value.isMultiple(of: 2) ? value : nil
        }
        .sync(
            onTermination: {
                terminationCount.write { $0 += 1 }
            },
            { value in
                values.write { $0.append(value) }
            }
        )

        observer.observe(1)
        observer.observe(2)

        #expect(values.read() == [nil, 2])
        #expect(terminationCount.read() == 0)

        observer.observe(nil)

        #expect(terminationCount.read() == 1)
    }

    @Test
    func sync_optionalInputNilIsValue() {
        let values = Synchronized<[Int?]>(.unfair, [])
        let terminationCount = Synchronized(.unfair, 0)
        let observer: ValueObserver<Int?> = .sync(
            onTermination: {
                terminationCount.write { $0 += 1 }
            },
            { value in
                values.write { $0.append(value) }
            }
        )

        observer.observe(.some(nil))

        #expect(values.read() == [nil])
        #expect(terminationCount.read() == 0)

        observer.observe(nil)

        #expect(terminationCount.read() == 1)
    }

    @Test
    func queue_schedulesValuesAndTermination() {
        let queue = DispatchQueue(label: "ValueObserverBuilderTests.queue")
        let events = Synchronized<[String]>(.unfair, [])
        let completed = DispatchSemaphore(value: 0)
        let observer: ValueObserver<Int> = .map { value in
            dispatchPrecondition(condition: .notOnQueue(queue))
            events.write { $0.append("before") }
            return value
        }
        .queue(queue)
        .filter { _ in
            dispatchPrecondition(condition: .onQueue(queue))
            events.write { $0.append("after") }
            return true
        }
        .sync(
            onTermination: {
                dispatchPrecondition(condition: .onQueue(queue))
                events.write { $0.append("terminate") }
                completed.signal()
            },
            { _ in
                dispatchPrecondition(condition: .onQueue(queue))
                events.write { $0.append("sync") }
            }
        )

        observer.observe(1)
        observer.observe(nil)

        #expect(completed.wait(timeout: .now() + 1) == .success)
        #expect(events.read() == ["before", "after", "sync", "terminate"])
    }

    @Test
    func starters_contextualTypesAndCurrentValue() {
        let filterValues = Synchronized<[Int]>(.unfair, [])
        let filterObserver: ValueObserver<Int> = .filter { $0 > 0 }
            .sync { value in filterValues.write { $0.append(value) } }
        filterObserver.observe(-1)
        filterObserver.observe(1)
        #expect(filterValues.read() == [1])

        let compactMappedValues = Synchronized<[Int]>(.unfair, [])
        let compactMapObserver: ValueObserver<Int> = .compactMap { value in
            value > 0 ? value : nil
        }
        .sync { value in compactMappedValues.write { $0.append(value) } }
        compactMapObserver.observe(-1)
        compactMapObserver.observe(2)
        #expect(compactMappedValues.read() == [2])

        let queueCompleted = DispatchSemaphore(value: 0)
        let queueObserver: ValueObserver<Int> = .queue(.global())
            .sync { _ in queueCompleted.signal() }
        queueObserver.observe(1)
        #expect(queueCompleted.wait(timeout: .now() + 1) == .success)

        let currentValues = Synchronized<[Int]>(.unfair, [])
        let store = ValueStore(initialValue: 7)
        let cancellation = store.observe(
            includingCurrentValue: true,
            .map(\.new).sync { value in
                currentValues.write { $0.append(value) }
            }
        )

        #expect(currentValues.read() == [7])
        withExtendedLifetime(cancellation) {}
    }

    @Test
    func pipeline_deliversPayload() {
        let queue = DispatchQueue(label: "ValueObserverBuilderTests.acceptanceQueue")
        let completed = DispatchSemaphore(value: 0)
        let payloads = Synchronized<[ValueObserverBuilderPayload]>(.unfair, [])
        let store = ValueStore(
            initialValue: ValueObserverBuilderState(isValid: false, payload: nil)
        )
        let cancellation = store.observable.observe(
            .map(\.new)
            .filter { $0.isValid }
            .compactMap(\.payload)
            .queue(queue)
            .sync { payload in
                payloads.write { $0.append(payload) }
                completed.signal()
            }
        )

        store.update(.init(isValid: false, payload: .init(value: 1)))
        store.update(.init(isValid: true, payload: nil))
        store.update(.init(isValid: true, payload: .init(value: 2)))

        #expect(completed.wait(timeout: .now() + 1) == .success)
        #expect(payloads.read() == [.init(value: 2)])
        withExtendedLifetime(cancellation) {}
    }

    @Test
    func async_processesValuesSequentially() async {
        let gate = ValueObserverBuilderGate()
        let (events, continuation) = AsyncStream<String>.makeStream()
        var iterator = events.makeAsyncIterator()
        let observer: ValueObserver<Int> = .async(
            onTermination: {
                continuation.yield("terminate")
                continuation.finish()
            },
            { value in
                continuation.yield("\(value) start")
                await gate.wait(for: value)
                continuation.yield("\(value) end")
            }
        )

        observer.observe(1)
        observer.observe(2)
        observer.observe(3)

        #expect(await iterator.next() == "1 start")
        await gate.release(1)
        #expect(await iterator.next() == "1 end")
        #expect(await iterator.next() == "2 start")
        await gate.release(2)
        #expect(await iterator.next() == "2 end")
        #expect(await iterator.next() == "3 start")
        await gate.release(3)
        #expect(await iterator.next() == "3 end")

        observer.observe(nil)
        observer.observe(nil)

        #expect(await iterator.next() == "terminate")
        #expect(await iterator.next() == nil)
    }

    @Test
    @MainActor
    func async_inheritsIsolationAndAllowsNonSendableCapture() async {
        let state = ValueObserverBuilderNonSendableState()
        let (completion, continuation) = AsyncStream<Void>.makeStream()
        var iterator = completion.makeAsyncIterator()
        var store: ValueStore<Int>? = ValueStore(initialValue: 0)
        let cancellation = store!.observe(
            .async(
                onTermination: {
                    state.terminated = true
                    continuation.yield()
                    continuation.finish()
                },
                { change in
                    state.values.append(change.new)
                }
            )
        )

        store?.update(1)
        store = nil

        _ = await iterator.next()
        #expect(state.values == [1])
        #expect(state.terminated)
        withExtendedLifetime(cancellation) {}
    }

    @Test
    @MainActor
    func async_cancellationWithoutSourceTermination() async {
        let store = ValueStore(initialValue: 0)
        let terminationCount = Synchronized(.unfair, 0)
        let (deinitialized, continuation) = AsyncStream<Void>.makeStream()
        var iterator = deinitialized.makeAsyncIterator()
        var state: ValueObserverBuilderNonSendableState? = .init {
            continuation.yield()
            continuation.finish()
        }
        let weakState = Weak(state)

        let cancellation = store.observe(
            .map(\.new).async(
                onTermination: {
                    terminationCount.write { $0 += 1 }
                },
                { [state] value in
                    state?.values.append(value)
                }
            )
        )
        state = nil

        cancellation.cancel()
        _ = await iterator.next()

        #expect(weakState.value == nil)
        #expect(terminationCount.read() == 0)
    }

    @Test
    func queue_terminationAfterObserverRelease() {
        let queue = DispatchQueue(label: "ValueObserverBuilderTests.terminationQueue")
        queue.suspend()
        let terminated = DispatchSemaphore(value: 0)

        func sendTermination() {
            let observer: ValueObserver<Int> = .queue(queue)
                .async(
                    isolation: nil,
                    onTermination: {
                        terminated.signal()
                    },
                    { _ in }
                )
            observer.observe(nil)
        }

        sendTermination()
        queue.resume()

        #expect(terminated.wait(timeout: .now() + 1) == .success)
    }
}
