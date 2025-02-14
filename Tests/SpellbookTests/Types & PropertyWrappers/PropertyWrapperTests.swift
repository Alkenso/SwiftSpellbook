import SpellbookFoundation

import Foundation
import XCTest

class PropertyWrapperTests: XCTestCase {
    func test_clamping() {
        @Clamped(0 ... 10) var a = 15
        XCTAssertEqual(a, 10)
        
        a = 0
        XCTAssertEqual(a, 0)
        
        a = -5
        XCTAssertEqual(a, 0)
        
        a = 3
        XCTAssertEqual(a, 3)
    }
    
    func test_Indirect_valueType() throws {
        var a = Indirect(wrappedValue: 123)
        var b = a
        
        a.wrappedValue = 10
        b.wrappedValue = 20
        
        XCTAssertEqual(a.wrappedValue, 10)
        XCTAssertEqual(b.wrappedValue, 20)
    }
    
    func test_Indirect_codable() throws {
        struct Test: Codable {
            @Indirect var value = 123
        }
        let data = try JSONEncoder().encode(Test())
        let string = try String(data: data, encoding: .utf8).get()
        XCTAssertEqual(string, #"{"value":123}"#)
        
        XCTAssertEqual(try JSONDecoder().decode(Test.self, from: data).value, 123)
    }
    
    func test_Indirect_codable_optional() throws {
        struct Test: Codable {
            @Indirect var value: Int?
        }
        let jsonValue = "{}"
        XCTAssertEqual(try JSONDecoder().decode(Test.self, from: Data(jsonValue.utf8)).value, nil)
        XCTAssertEqual(try JSONEncoder().encode(Test()), Data(jsonValue.utf8))
        
        let jsonArray = #"[{},{},{}]"#
        XCTAssertEqual(try JSONDecoder().decode([Test].self, from: Data(jsonArray.utf8)).count, 3)
        XCTAssertEqual(try JSONEncoder().encode([Test](repeating: Test(), count: 3)), Data(jsonArray.utf8))
    }
    
    func test_ValueView() {
        XCTAssertEqual(ValueView.constant(10).value, 10)
        
        var value1 = 1
        @ValueViewed var view1 = value1
        
        XCTAssertEqual(view1, value1)
        value1 = 10
        XCTAssertEqual(view1, value1)
        value1 = 20
        XCTAssertEqual($view1.value, value1)
        
        var value2 = 1
        let view2 = ValueView { value2 }
        
        XCTAssertEqual(view2.value, value2)
        value2 = 10
        XCTAssertEqual(view2.value, value2)
    }
}
