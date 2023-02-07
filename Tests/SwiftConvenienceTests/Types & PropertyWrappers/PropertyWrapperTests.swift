import SwiftConvenience

import Foundation
import XCTest

class PropertyWrapperTests: XCTestCase {
    func test_clamping() {
        @Clamping(0 ... 10) var a = 15
        XCTAssertEqual(a, 10)
        
        a = 0
        XCTAssertEqual(a, 0)
        
        a = -5
        XCTAssertEqual(a, 0)
        
        a = 3
        XCTAssertEqual(a, 3)
    }
    
    func test_Box_codable() throws {
        struct Test: Codable {
            @Box var value = 123
        }
        let data = try JSONEncoder().encode(Test())
        let string = try String(data: data, encoding: .utf8).get()
        XCTAssertEqual(string, #"{"value":123}"#)
        
        XCTAssertEqual(try JSONDecoder().decode(Test.self, from: data).value, 123)
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
        
        let jsonArray = #"[{},{},{}]"#
        XCTAssertEqual(try JSONDecoder().decode([Test].self, from: Data(jsonArray.utf8)).count, 3)
    }
}
