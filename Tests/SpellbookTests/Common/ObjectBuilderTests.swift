import SpellbookFoundation

import XCTest

class ObjectBuilderTests: XCTestCase {
    struct Foo: Equatable, ValueBuilder {
        var a = 10
        var b = "qwerty"
    }
    
    func test() {
        XCTAssertEqual(Foo().set(\.a, 15).set(\.b, "q").set(\.a, 1), Foo(a: 1, b: "q"))
        
        XCTAssertEqual(Foo().if(true, then: { $0.a = 1 }), Foo(a: 1))
        XCTAssertEqual(Foo().if(false, then: { $0.a = 1 }), Foo())
        XCTAssertEqual(Foo().if(true, then: { $0.a = 1 }, else: { $0.a = 2 }), Foo(a: 1))
        XCTAssertEqual(Foo().if(false, then: { $0.a = 1 }, else: { $0.a = 2 }), Foo(a: 2))
        
        XCTAssertEqual(Foo().ifLet(1, then: { $0.a = $1 }), Foo(a: 1))
        XCTAssertEqual(Foo().ifLet(nil as Int?, then: { $0.a = $1 }), Foo())
        XCTAssertEqual(Foo().ifLet(1, then: { $0.a = $1 }, else: { $0.a = 2 }), Foo(a: 1))
        XCTAssertEqual(Foo().ifLet(nil as Int?, then: { $0.a = $1 }, else: { $0.a = 2 }), Foo(a: 2))
    }
}
