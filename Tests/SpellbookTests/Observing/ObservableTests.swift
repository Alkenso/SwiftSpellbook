import SpellbookFoundation
import SpellbookTestUtils

import Testing

private struct Branch: Equatable, Sendable {
    var leaf = 0
}

private struct Root: Equatable, Sendable {
    var a = Branch()
    var b = Branch()
}

@Suite
struct ValueObservableTests {
    @Test
    func value() {
        let store = ValueStore(initialValue: 10)
        let observable = store.observable
        #expect(observable.value == 10)

        store.update(20)
        #expect(observable.value == 20)
    }

    @Test
    func dynamicMemberLookup() {
        let store = ValueStore(initialValue: Root())
        let observable = store.observable

        store.update(\.a.leaf, 5)
        #expect(observable.a.leaf == 5)
    }

    @Test
    func simpleNotify() async {
        let store = ValueStore(initialValue: 0)
        var iterator = store.observable.stream().makeAsyncIterator()

        store.update(1)
        #expect(store.observable.value == 1)

        let change = await iterator.next()
        #expect(change?.old == 0)
        #expect(change?.new == 1)
    }

    @Test
    func simpleNotify_includingCurrentValue() async {
        let store = ValueStore(initialValue: 0)
        var iterator = store.observable.stream(includingCurrentValue: true).makeAsyncIterator()

        let initialChange = await iterator.next()
        #expect(initialChange?.old == 0)
        #expect(initialChange?.new == 0)

        store.update(1)

        let change = await iterator.next()
        #expect(change?.old == 0)
        #expect(change?.new == 1)
    }

    @Test
    func asyncNotify() async {
        let store = ValueStore(initialValue: 0)
        var changes: [ValueChange<Int>?] = []
        let cancellation = store.observable.observe { changes.append($0) }

        store.update(1)

        await Task.yield()
        #expect(changes.count == 1)

        cancellation.cancel()
        await Task.yield()
        #expect(changes.count == 2)

        #expect(changes[0]?.old == 0)
        #expect(changes[0]?.new == 1)
        #expect(changes[1] == nil)
    }

    @Test
    func scope() async {
        let store = ValueStore(initialValue: Root())
        let observable = store.observable
        let branchA = observable.scope(\.a)
        let leafA = branchA.scope(\.leaf)

        var iteratorRoot = observable.stream().makeAsyncIterator()
        var iteratorBranchA = branchA.stream().makeAsyncIterator()
        var iteratorLeafA = leafA.stream().makeAsyncIterator()

        store.update(\.a.leaf, 1)
        #expect(observable.a.leaf == 1)
        #expect(branchA.leaf == 1)
        #expect(leafA.value == 1)
        #expect(await iteratorRoot.next()?.map(\.a.leaf) == .init(old: 0, new: 1))
        #expect(await iteratorBranchA.next()?.map(\.leaf) == .init(old: 0, new: 1))
        #expect(await iteratorLeafA.next() == .init(old: 0, new: 1))
    }

    @Test
    func optional() async {
        let store = ValueStore(initialValue: 10)
        let observable = store.observable.optional()
        #expect(observable.value == 10)

        var iterator = observable.stream().makeAsyncIterator()
        store.update(20)
        #expect(await iterator.next() == .init(old: 10, new: 20))
    }

    @Test
    func unwrapped() async {
        let store = ValueStore<Int?>(initialValue: nil)
        let observable = store.observable.unwrapped(default: -1)
        #expect(observable.value == -1)

        var iterator = observable.stream().makeAsyncIterator()
        store.update(5)
        #expect(await iterator.next() == .init(old: -1, new: 5))
    }

    @Test
    func constant() async {
        let observable = ValueObservable.constant(10)
        #expect(observable.value == 10)

        var iterator = observable.stream(includingCurrentValue: true).makeAsyncIterator()
        let change = await iterator.next()
        #expect(change?.old == 10)
        #expect(change?.new == 10)
    }

    @Test
    func notify_cancel() async {
        var store: ValueStore! = ValueStore(initialValue: 0)
        var iterator = store.observable.stream().makeAsyncIterator()

        store.update(1)
        #expect(await iterator.next() == .init(old: 0, new: 1))

        store = nil
        #expect(await iterator.next() == nil)
    }
}
