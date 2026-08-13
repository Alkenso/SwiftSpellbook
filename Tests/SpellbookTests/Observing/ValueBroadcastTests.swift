import SpellbookFoundation

import Testing

@Suite
struct ValueBroadcastTests {
    @Test
    func notify() {
        let broadcast = ValueBroadcast<Int>()
        broadcast.notifyQueue = nil
        let firstValues = Synchronized<[Int]>(.unfair)
        let secondValues = Synchronized<[Int]>(.unfair)
        let subscriptions = [
            broadcast.observe(.init { value in
                if let value { firstValues.append(value) }
            }),
            broadcast.observe(includingCurrentValue: true, .init { value in
                if let value { secondValues.append(value) }
            }),
        ]

        [10, 20, 30].forEach(broadcast.notify)

        #expect(firstValues.read() == [10, 20, 30])
        #expect(secondValues.read() == [10, 20, 30])
        withExtendedLifetime(subscriptions) {}
    }

    @Test
    func notify_cancel() {
        let broadcast = ValueBroadcast<Int>()
        broadcast.notifyQueue = nil
        let values = Synchronized<[Int]>(.unfair)
        let subscription = broadcast.observe(.init { value in
            if let value { values.append(value) }
        })

        broadcast.notify(1)
        subscription.cancel()
        broadcast.notify(2)

        #expect(values.read() == [1])
    }

    @Test
    func stream() async {
        let broadcast = ValueBroadcast<Int>()
        broadcast.notifyQueue = nil
        var iterator = broadcast.stream().makeAsyncIterator()

        broadcast.notify(42)

        #expect(await iterator.next() == 42)
    }
}
