@testable import SpellbookFoundation

import XCTest

class ValueBuilderTests: XCTestCase {
    struct Foo: Equatable {
        var a = 10
        var b = "qwerty"
    }
    
    private var builder: ValueBuilder<Foo> { ValueBuilder(value: Foo()) }
    
    func test_set() {
        XCTAssertEqual(builder.set(\.a, 15).set(\.b, "q").set(\.a, 1).value, Foo(a: 1, b: "q"))
        XCTAssertEqual(builder.set(\.a, nil).value, Foo())
        XCTAssertEqual(builder.set(\.a, 5).set(\.a, nil).value, Foo(a: 5))
    }
    
    func test_if() {
        XCTAssertEqual(builder.if(true, then: { $0.a = 1 }).value, Foo(a: 1))
        XCTAssertEqual(builder.if(false, then: { $0.a = 1 }).value, Foo())
        XCTAssertEqual(builder.if(true, then: { $0.a = 1 }, else: { $0.a = 2 }).value, Foo(a: 1))
        XCTAssertEqual(builder.if(false, then: { $0.a = 1 }, else: { $0.a = 2 }).value, Foo(a: 2))
    }
    
    func test_ifLet() {
        XCTAssertEqual(builder.ifLet(1, then: { $0.a = $1 }).value, Foo(a: 1))
        XCTAssertEqual(builder.ifLet(nil as Int?, then: { $0.a = $1 }).value, Foo())
        XCTAssertEqual(builder.ifLet(1, then: { $0.a = $1 }, else: { $0.a = 2 }).value, Foo(a: 1))
        XCTAssertEqual(builder.ifLet(nil as Int?, then: { $0.a = $1 }, else: { $0.a = 2 }).value, Foo(a: 2))
    }
    
    func test_modify() {
        XCTAssertEqual(builder.modify { $0.a = 1; $0.b = "q" }.value, Foo(a: 1, b: "q"))
    }
    
    func test_chaining() {
        let value = builder
            .set(\.a, 1)
            .if(true, then: { $0.b = "if" })
            .ifLet(2, then: { $0.a += $1 })
            .modify { $0.b += "-modified" }
            .value
        XCTAssertEqual(value, Foo(a: 3, b: "if-modified"))
    }
    
    func test_doesNotMutateOriginal() {
        let original = builder
        _ = original.set(\.a, 1).modify { $0.b = "q" }
        XCTAssertEqual(original.value, Foo())
    }
}
