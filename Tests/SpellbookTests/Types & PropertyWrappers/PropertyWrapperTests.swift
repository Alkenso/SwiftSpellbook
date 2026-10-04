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
    
    func test_EmptyDecodable() throws {
        struct Test: Codable, Equatable {
            @EmptyDecodable var items: [String] = []
            @EmptyDecodable var name = "default"
        }
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(Test.self, from: Data(#"{}"#.utf8)), Test(items: [], name: ""))
        XCTAssertEqual(try decoder.decode(Test.self, from: Data(#"{"items":null,"name":null}"#.utf8)), Test(items: [], name: ""))
        XCTAssertEqual(try decoder.decode(Test.self, from: Data(#"{"items":["a"],"name":"b"}"#.utf8)), Test(items: ["a"], name: "b"))
        XCTAssertThrowsError(try decoder.decode(Test.self, from: Data(#"{"items":1}"#.utf8)))

        XCTAssertEqual(try decoder.decode([EmptyDecodable<[Int]>].self, from: Data(#"[null,[1]]"#.utf8)), [.init(), .init(wrappedValue: [1])])

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(Test(items: ["a"], name: "b"))
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"items":["a"],"name":"b"}"#)
    }

    func test_ValueView() {
        XCTAssertEqual(ValueView.constant(10).value, 10)
        
        nonisolated(unsafe) var value1 = 1
        @ValueViewed var view1 = value1
        
        XCTAssertEqual(view1, value1)
        value1 = 10
        XCTAssertEqual(view1, value1)
        value1 = 20
        XCTAssertEqual($view1.value, value1)
        
        nonisolated(unsafe) var value2 = 1
        let view2 = ValueView { value2 }
        
        XCTAssertEqual(view2.value, value2)
        value2 = 10
        XCTAssertEqual(view2.value, value2)
    }
}
