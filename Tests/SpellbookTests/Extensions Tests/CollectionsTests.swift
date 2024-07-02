import SpellbookFoundation

import XCTest

class ArrayTests: XCTestCase {
    func test_mutateElements() {
        XCTAssertEqual([10, 20, 30].mutatingMap { $0 += 5 }, [15, 25, 35])
        
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
}

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

class CollectionTests: XCTestCase {
    func test_removeFirst() {
        var arr = [1, 2, 20, 30]
        XCTAssertEqual(arr.removeFirst { $0 < 10 }, 1)
        XCTAssertEqual(arr.removeFirst { $0 < 10 }, 2)
        XCTAssertEqual(arr.removeFirst { $0 < 10 }, nil)
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
}
