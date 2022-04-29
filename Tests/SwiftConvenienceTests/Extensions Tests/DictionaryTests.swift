import SwiftConvenience

import XCTest

class DictionaryTests: XCTestCase {
    func test_keyPath() {
        let dict: [String : Any] = [
            "lv1_key1": "lv1_val1",
            "lv1_key2": [
                2: "lv2_val2",
                "lv2_key1": 21,
                "lv2_key2": [
                    "lv3_key1": "lv3_val1"
                ]
            ]
        ]
        
        XCTAssertNotNil(dict[keyPath: []])
        XCTAssertEqual(dict[keyPath: ["lv1_key1"]] as? String, "lv1_val1")
        XCTAssertEqual(dict[keyPath: ["lv1_key2", 2]] as? String, "lv2_val2")
        XCTAssertEqual(dict[keyPath: ["lv1_key2", "lv2_key1"]] as? Int, 21)
        XCTAssertEqual(dict[keyPath: ["lv1_key2", "lv2_key2", "lv3_key1"]] as? String, "lv3_val1")
        
        
        XCTAssertNotNil(dict[dotPath: ""])
        XCTAssertEqual(dict[dotPath: "lv1_key1"] as? String, "lv1_val1")
        XCTAssertNil(dict[dotPath: "lv1_key2.2"])
        XCTAssertEqual(dict[dotPath: "lv1_key2.lv2_key1"] as? Int, 21)
        XCTAssertEqual(dict[dotPath: "lv1_key2.lv2_key2.lv3_key1"] as? String, "lv3_val1")
    }
    
    func test_keyPath_DictArrayMix() {
        let dict: [String : Any] = [
            "lv1_key1": [ // Mested Array<Any>
                "lv2_val1",
                ["lv3_val1", "lv3_val2"], // Mested Array<String>
                [ // Mested Array<Dictionary>
                    "lv3_key1": [
                        "lv4_key1": "lv4_value1",
                        "lv4_key2": "lv4_value2",
                    ]
                ]
            ]
        ]
        
        XCTAssertEqual(dict[keyPath: ["lv1_key1", [0]]] as? String, "lv2_val1")
        XCTAssertEqual(dict[keyPath: ["lv1_key1", [1], [Int.max]]] as? String, "lv3_val2")
        XCTAssertEqual(dict[keyPath: ["lv1_key1", [2], "lv3_key1", "lv4_key1"]] as? String, "lv4_value1")
        
        XCTAssertEqual(dict[dotPath: "lv1_key1.[0]"] as? String, "lv2_val1")
        XCTAssertEqual(dict[dotPath: "lv1_key1.[1].[*]"] as? String, "lv3_val2")
        XCTAssertEqual(dict[dotPath: "lv1_key1.[2].lv3_key1.lv4_key1"] as? String, "lv4_value1")
    }
    
    func test_insertKeyPath() throws {
        var dict: [String : Any] = [:]
        
        try dict.insert(value: "lv1_val1", at: ["lv1_key1"])
        try dict.insert(value: "lv2_val2", at: ["lv1_key2", 2])
        try dict.insert(value: 21, at: ["lv1_key2", "lv2_key1"])
        try dict.insert(value: "lv3_val1", at: ["lv1_key2", "lv2_key2", "lv3_key1"])
        
        XCTAssertEqual(dict[keyPath: ["lv1_key1"]] as? String, "lv1_val1")
        XCTAssertEqual(dict[keyPath: ["lv1_key2", 2]] as? String, "lv2_val2")
        XCTAssertEqual(dict[keyPath: ["lv1_key2", "lv2_key1"]] as? Int, 21)
        XCTAssertEqual(dict[keyPath: ["lv1_key2", "lv2_key2", "lv3_key1"]] as? String, "lv3_val1")
    }
    
    func test_insertDotPath() throws {
        var dict: [String : Any] = [:]
        
        try dict.insert(value: "lv1_val1", at: ["lv1_key1"])
        try dict.insert(value: "lv2_val2", at: "lv1_key2.2")
        try dict.insert(value: 21, at: "lv1_key2.lv2_key1")
        try dict.insert(value: "lv3_val1", at: "lv1_key2.lv2_key2.lv3_key1")
        
        XCTAssertEqual(dict[keyPath: ["lv1_key1"]] as? String, "lv1_val1")
        XCTAssertEqual(dict[keyPath: ["lv1_key2", "2"]] as? String, "lv2_val2")
        XCTAssertEqual(dict[keyPath: ["lv1_key2", "lv2_key1"]] as? Int, 21)
        XCTAssertEqual(dict[keyPath: ["lv1_key2", "lv2_key2", "lv3_key1"]] as? String, "lv3_val1")
    }
}
