import SpellbookFoundation

import Foundation
import Testing

@Suite
struct ValueAskTests {
    @Test
    func empty() async {
        let ask = ValueAsk<String, Int>()

        #expect(await ask.ask("some request").isEmpty)
    }

    @Test
    func ask_multipleResponders() async {
        let request = "some request"
        let ask = ValueAsk<String, Int>()
        let subscriptions = [
            ask.attach(.init { receivedRequest in
                #expect(receivedRequest == request)
                return 1
            }),
            ask.attach(.init(queue: .global()) { receivedRequest, reply in
                #expect(receivedRequest == request)
                reply(2)
            }),
        ]

        let responses = await ask.ask(request)

        #expect(Set(responses) == [1, 2])
        withExtendedLifetime(subscriptions) {}
    }

    @Test
    func ask_concurrent() async {
        let ask = ValueAsk<Int, Int>()
        let subscription = ask.attach(.init { $0 * 2 })

        await withTaskGroup(of: (Int, [Int]).self) { group in
            for request in 0..<100 {
                group.addTask { (request, await ask.ask(request)) }
            }

            for await (request, responses) in group {
                #expect(responses == [request * 2])
            }
        }
        withExtendedLifetime(subscription) {}
    }

    @Test
    func stream() async {
        let ask = ValueAsk<Void, Int>()
        let subscriptions = [
            ask.attach(.init { 1 }),
            ask.attach(.init { 2 }),
            ask.attach(.init { 3 }),
        ]
        var responses: [Int] = []

        for await response in ask.stream(()) {
            responses.append(response)
        }

        #expect(Set(responses) == [1, 2, 3])
        withExtendedLifetime(subscriptions) {}
    }

    @Test
    func attach_cancel() async {
        let ask = ValueAsk<Void, Int>()
        let retained = ask.attach(.init { 1 })
        let cancelled = ask.attach(.init { 2 })
        cancelled.cancel()

        #expect(await ask.ask(()) == [1])
        withExtendedLifetime(retained) {}
    }

}
