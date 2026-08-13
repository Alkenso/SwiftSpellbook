import SpellbookFoundation

import Testing

private struct Branch: Equatable, Sendable {
    var leaf = 0
}

private struct Root: Equatable, Sendable {
    var a = Branch()
    var b = Branch()
}

extension ValueChange: Equatable where Value: Equatable {
    public static func == (lhs: ValueChange<Value>, rhs: ValueChange<Value>) -> Bool {
        lhs.old == rhs.old && lhs.new == rhs.new
    }
}

@Suite
struct ValueStoreTests {
    @Test
    func update_resultAndContext() async {
        let store = ValueStore(initialValue: 10)
        var iterator = store.stream().makeAsyncIterator()

        let oldValue = store.update(context: "test context") {
            exchange(&$0, with: 20)
        }
        let change = await iterator.next()

        #expect(oldValue == 10)
        #expect(store.value == 20)
        #expect(change?.context as? String == "test context")
    }

    @Test
    func simpleNotify() async {
        let store = ValueStore(initialValue: 0)
        var iterator = store.stream().makeAsyncIterator()
        
        store.update(1)
        #expect(store.value == 1)
        
        let change = await iterator.next()
        #expect(change?.old == 0)
        #expect(change?.new == 1)
    }
    
    @Test
    func simpleNotify_includingCurrentValue() async {
        let store = ValueStore(initialValue: 0)
        var iterator = store.stream(includingCurrentValue: true).makeAsyncIterator()
        
        let initialChange = await iterator.next()
        #expect(initialChange?.old == 0)
        #expect(initialChange?.new == 0)
        
        store.update(1)
        #expect(store.value == 1)
        
        let change = await iterator.next()
        #expect(change?.old == 0)
        #expect(change?.new == 1)
    }
    
    @Test
    func asyncNotify() async {
        let store = ValueStore(initialValue: 0)
        var changes: [ValueChange<Int>?] = []
        let cancellation = store.observe { changes.append($0) }
        
        store.update(1)
        #expect(store.value == 1)
        
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
    func hierarchicalUpdate() async {
        let root = ValueStore<Root>(initialValue: .init())
        let branchA = root.scope(\.a)
        let leafA = branchA.scope(\.leaf)
        
        var iteratorRoot = root.stream().makeAsyncIterator()
        var iteratorBranchA = branchA.stream().makeAsyncIterator()
        var iteratorLeafA = leafA.stream().makeAsyncIterator()
        
        root.update(\.a.leaf, 1)
        #expect(root.a.leaf == 1)
        #expect(branchA.leaf == 1)
        #expect(leafA.value == 1)
        #expect(await iteratorRoot.next()?.map(\.a.leaf) == .init(old: 0, new: 1))
        #expect(await iteratorBranchA.next()?.map(\.leaf) == .init(old: 0, new: 1))
        #expect(await iteratorLeafA.next() == .init(old: 0, new: 1))
        
        branchA.update(\.leaf, 2)
        #expect(root.a.leaf == 2)
        #expect(branchA.leaf == 2)
        #expect(leafA.value == 2)
        #expect(await iteratorRoot.next()?.map(\.a.leaf) == .init(old: 1, new: 2))
        #expect(await iteratorBranchA.next()?.map(\.leaf) == .init(old: 1, new: 2))
        #expect(await iteratorLeafA.next() == .init(old: 1, new: 2))
        
        leafA.update(3)
        #expect(root.a.leaf == 3)
        #expect(branchA.leaf == 3)
        #expect(leafA.value == 3)
        #expect(await iteratorRoot.next()?.map(\.a.leaf) == .init(old: 2, new: 3))
        #expect(await iteratorBranchA.next()?.map(\.leaf) == .init(old: 2, new: 3))
        #expect(await iteratorLeafA.next() == .init(old: 2, new: 3))
    }

    @Test
    func unwrapped_default() {
        let root = ValueStore<Int?>(initialValue: nil)
        let unwrapped = root.unwrapped(default: 10)

        unwrapped.update(20)

        #expect(root.value == nil)
        #expect(unwrapped.value == 10)
    }

    @Test
    func unwrapped_mergeIntoNil() {
        let root = ValueStore<Int?>(initialValue: nil)
        let unwrapped = root.unwrapped(default: 10, mergeIntoNil: true)

        unwrapped.update(20)

        #expect(root.value == 20)
        #expect(unwrapped.value == 20)
    }

    @Test
    func optional_fallback() {
        let root = ValueStore(initialValue: 10)
        let optional = root.optional(fallback: 20)

        optional.update(nil)

        #expect(root.value == 20)
        #expect(optional.value == 20)
    }
    
    @Test
    func notify_deadIntermediate() async {
        let root = ValueStore(initialValue: Root())
        let leafA = root.scope(\.a).scope(\.leaf)
        let leafB = root.scope(\.b).scope(\.leaf)
        
        var iteratorLeafA = leafA.stream().makeAsyncIterator()
        var iteratorLeafB = leafB.stream().makeAsyncIterator()
        
        root.update {
            $0.a.leaf = 1
            $0.b.leaf = 2
        }
        
        #expect(leafA.value == 1)
        #expect(leafB.value == 2)
        #expect(await iteratorLeafA.next() == .init(old: 0, new: 1))
        #expect(await iteratorLeafB.next() == .init(old: 0, new: 2))
    }
    
    @Test
    func notify_cancel() async {
        var root: ValueStore! = ValueStore(initialValue: Root())
        var iteratorLeafA = root.scope(\.a).scope(\.leaf).stream().makeAsyncIterator()
        
        root.update { $0.a.leaf = 1 }
        #expect(await iteratorLeafA.next() == .init(old: 0, new: 1))
        
        root = nil
        #expect(await iteratorLeafA.next() == nil)
    }
}
