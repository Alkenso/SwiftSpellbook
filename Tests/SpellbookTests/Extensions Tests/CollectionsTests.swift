import SpellbookFoundation

import XCTest

class DictionaryTests: XCTestCase {
    func test_subscript_popAll() {
        var dict = [1: "q", 2: "w"]
        XCTAssertEqual(dict.popAll(), [1: "q", 2: "w"])
        XCTAssertEqual(dict, [:])
    }
    
    func test_subscript_popAll_where() {
        var dict = [1: "q", 2: "w", 3: "e", 4: "r"]
        XCTAssertEqual(dict.popAll { $0.key == 1 || $0.value == "w" }, [1: "q", 2: "w"])
        XCTAssertEqual(dict, [3: "e", 4: "r"])
        
        XCTAssertEqual(dict.popAll { _ in false }, [:])
        XCTAssertEqual(dict, [3: "e", 4: "r"])
        
        XCTAssertEqual(dict.popAll { _ in true }, [3: "e", 4: "r"])
        XCTAssertEqual(dict, [:])
    }
    
    func test_filterRemaining() {
        let dict = [1: "q", 2: "w", 3: "e", 4: "r"]
        var remaining: [Int: String] = [:]
        let filtered = dict.filter(remaining: &remaining) { $0.key % 2 == 0 }
        XCTAssertEqual(filtered, [2: "w", 4: "r"])
        XCTAssertEqual(remaining, [1: "q", 3: "e"])
    }
}

class ArrayTests: XCTestCase {
    func test_initCreate() {
        XCTAssertEqual(Array<Int>(count: 3, create: { 1 }), [1, 1, 1])
        XCTAssertEqual(Array<Int>(count: 3, create: 1), [1, 1, 1])
        
        class Foo {}
        let refsFoo = Array<Foo>(count: 2, create: Foo.init)
        XCTAssertTrue(refsFoo[0] !== refsFoo[1])
        
        struct Bar {
            var value: Int
        }
        var counter = 0
        let refsBar = Array<Bar>(count: 2) {
            defer { counter += 1 }
            return Bar(value: counter)
        }
        XCTAssertEqual(refsBar[0].value, 0)
        XCTAssertEqual(refsBar[1].value, 1)
    }
}

class SequenceTests: XCTestCase {
    func test_keyedMap() {
        XCTAssertEqual(
            ["q", "www", "ee"].keyedMap(\.count),
            [KeyValue(1, "q"), KeyValue(3, "www"), KeyValue(2, "ee")]
        )
        
        struct Foo: Equatable {
            var val: String
            var opt: Int?
        }
        XCTAssertEqual(
            [Foo(val: "q", opt: 1), Foo(val: "w", opt: nil), Foo(val: "e", opt: 2)].keyedCompactMap(\.opt),
            [KeyValue(1, Foo(val: "q", opt: 1)), KeyValue(2, Foo(val: "e", opt: 2))]
        )
    }
    
    func test_mutatingMap() {
        XCTAssertEqual((1...3).mutatingMap { $0 += 5 }, [6, 7, 8])
    }
    
    func test_filterRemaining() {
        let arr = [1, 5, 11, 10]
        var remaining: [Int] = []
        let filtered = arr.filter(remaining: &remaining) { $0 % 5 == 0 }
        XCTAssertEqual(filtered, [5, 10])
        XCTAssertEqual(remaining, [1, 11])
    }
    
    func test_firstMapped() {
        let values = ["a", "1", "2", "b"]
        XCTAssertEqual(values.firstMapped { Int($0) }, 1)
    }
    
    func test_sorted_keyPath() {
        XCTAssertEqual(["aaa", "d", "cccc", "bb"].sorted(by: \.count), ["d", "bb", "aaa", "cccc"])
    }
    
    func test_sorted_options() {
        XCTAssertEqual(["1", "11", "12", "112"].sorted(), ["1", "11", "112", "12"])
        XCTAssertEqual(["1", "11", "12", "112"].sorted(options: .numeric), ["1", "11", "12", "112"])
    }
    
    func test_reduceDictionary() {
        let array = [
            KeyValue(1, "a"),
            KeyValue(2, "b"),
            KeyValue(3, "c"),
            KeyValue(1, "d"),
        ]
        XCTAssertEqual(array.reduce(keyedBy: \.key), [2: KeyValue(2, "b"), 3: KeyValue(3, "c"), 1: KeyValue(1, "d")])
        XCTAssertEqual(array.reduce(keyedBy: {
            $0.key != 3 ? $0.key : nil
        }), [2: KeyValue(2, "b"), 1: KeyValue(1, "d")])
        
        XCTAssertEqual(
            array.reduce(into: [2: KeyValue(2, "b1"), 5: KeyValue(5, "e")], keyedBy: \.key),
            [2: KeyValue(2, "b"), 3: KeyValue(3, "c"), 1: KeyValue(1, "d"), 5: KeyValue(5, "e")]
        )
    }
}

class CollectionTests: XCTestCase {
    func test_mutateElements() {
        var arr = [10, 20, 30]
        arr.mutateElements { $0 += 5 }
        XCTAssertEqual(arr, [15, 25, 35])
    }
    
    func test_appending() {
        XCTAssertEqual([].appending(10), [10])
        XCTAssertEqual([10, 20].appending(10), [10, 20, 10])
    }
    
    func test_subscript_safe() {
        XCTAssertEqual([Int]()[safe: 0], nil)
        XCTAssertEqual([10][safe: 0], 10)
        XCTAssertEqual([10][safe: 1], nil)
        XCTAssertEqual([10][safe: -1], nil)
        XCTAssertEqual(Array<Int>()[safe: -1], nil)
    }
    
    func test_subscript_popFirst() {
        var arr = [1, 2]
        XCTAssertEqual(arr.popFirst(), 1)
        XCTAssertEqual(arr, [2])
        
        XCTAssertEqual(arr.popFirst(), 2)
        XCTAssertEqual(arr, [])
        
        XCTAssertEqual(arr.popFirst(), nil)
        XCTAssertEqual(arr, [])
    }
    
    func test_subscript_popAll() {
        var arr = [1, 2]
        XCTAssertEqual(arr.popAll(), [1, 2])
        XCTAssertEqual(arr, [])
    }
    
    func test_subscript_popAll_where() {
        var arr = [1, 2, 3, 4]
        XCTAssertEqual(arr.popAll { $0 < 3 }, [1, 2])
        XCTAssertEqual(arr, [3, 4])
        
        XCTAssertEqual(arr.popAll { _ in false }, [])
        XCTAssertEqual(arr, [3, 4])
        
        XCTAssertEqual(arr.popAll { _ in true }, [3, 4])
        XCTAssertEqual(arr, [])
    }
    
    func test_removeFirst() {
        var arr = [1, 2, 20, 30]
        XCTAssertEqual(arr.removeFirst { $0 < 10 }, 1)
        XCTAssertEqual(arr.removeFirst { $0 < 10 }, 2)
        XCTAssertEqual(arr.removeFirst { $0 < 10 }, nil)
        XCTAssertThrowsError(try arr.removeFirst { _ in throw CommonError("") })
    }
    
    func test_popAll() {
        var arr = [1, 2, 20, 30]
        XCTAssertEqual(arr.popAll(), [1, 2, 20, 30])
        XCTAssertEqual(arr, [])
    }
    
    func test_popAll_where() {
        var arr = [1, 2, 20, 30]
        XCTAssertEqual(arr.popAll { $0 > 10 }, [20, 30])
        XCTAssertEqual(arr, [1, 2])
    }
    
    func test_firstIndex_property() {
        let arr = ["q", "ww", "eee", "rr"]
        XCTAssertEqual(arr.firstIndex(.equals(at: \.count, to: 2)), 1)
        if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            XCTAssertEqual(arr.indices(.equals(at: \.count, to: 2)), RangeSet([1, 3], within: arr))
        }
    }
    
    func test_updateFirst() {
        var arr = ["q", "ww", "eee", "rr"]
        arr.updateFirst("ttt", .where { $0.count == 3 })
        XCTAssertEqual(arr, ["q", "ww", "ttt", "rr"])
        
        arr.updateFirst("yy", .equals(at: \.count, to: 2))
        XCTAssertEqual(arr, ["q", "yy", "ttt", "rr"])
        
        arr.updateFirst("uuu", by: \.count)
        XCTAssertEqual(arr, ["q", "yy", "uuu", "rr"])
        
        arr.updateFirst("ii", .where { $0.count == 4 })
        XCTAssertEqual(arr, ["q", "yy", "uuu", "rr", "ii"])
    }
    
    func test_removePopRandom() throws {
        var arr = [1, 2]
        let removed = arr.removeRandom()
        XCTAssertFalse(arr.contains(removed))
        XCTAssertEqual(arr.count, 1)
        
        let popped = try XCTUnwrap(arr.popRandom())
        XCTAssertFalse(arr.contains(popped))
        XCTAssertEqual(arr.count, 0)
        
        XCTAssertNil(arr.popRandom())
    }
}
