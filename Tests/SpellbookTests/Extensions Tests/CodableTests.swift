import SpellbookFoundation

import XCTest

class CodableTests: XCTestCase {
    func test_PropertyListSerializable() throws {
        @PropertyListSerializable var anyDict = ["key1": "value1", "key2": 20]
        let data = try JSONEncoder().encode(_anyDict)
        
        let decoded = try JSONDecoder().decode(PropertyListSerializable<[String: Any]>.self, from: data)
        XCTAssertEqual(decoded.wrappedValue["key1"] as? String, "value1")
        XCTAssertEqual(decoded.wrappedValue["key2"] as? Int, 20)
    }
    
    func test_PropertyListSerializable_failure() throws {
        // Custom type is not compatible with PropertyListSerialization.
        struct Foo {}
        @PropertyListSerializable var custom: Any = Foo()
        XCTAssertThrowsError(try JSONEncoder().encode(_custom))
    }
    
    func test_JSONSerializable() throws {
        @JSONSerializable var anyDict = ["key1": "value1", "key2": 20]
        let data = try JSONEncoder().encode(_anyDict)
        
        let decoded = try JSONDecoder().decode(JSONSerializable<[String: Any]>.self, from: data)
        XCTAssertEqual(decoded.wrappedValue["key1"] as? String, "value1")
        XCTAssertEqual(decoded.wrappedValue["key2"] as? Int, 20)
    }
    
    func test_JSONSerializable_failure() throws {
        // `Date` is not compatible with JSON.
        @JSONSerializable var object: Any = Date()
        XCTAssertThrowsError(try JSONEncoder().encode(_object))
        
        // Custom type is not compatible with JSONSerialization.
        struct Foo {}
        @JSONSerializable var custom: Any = Foo()
        XCTAssertThrowsError(try JSONEncoder().encode(_custom))
    }
    
    func test_NSKeyedArchiveSerializable_dict() throws {
        @KeyedArchiveSerializable var anyDict = ["key1": "value1", "key2": 20] as NSDictionary
        let data = try JSONEncoder().encode(_anyDict)
        
        let decoded = try JSONDecoder().decode(KeyedArchiveSerializable<NSDictionary>.self, from: data)
        XCTAssertEqual(decoded.wrappedValue["key1"] as? String, "value1")
        XCTAssertEqual(decoded.wrappedValue["key2"] as? Int, 20)
    }
    
    func test_NSKeyedArchiveSerializable_error() throws {
        @KeyedArchiveSerializable var error = NSError(
            domain: "D",
            code: 10,
            userInfo: [NSDebugDescriptionErrorKey: "test"]
        )
        let data = try JSONEncoder().encode(_error)
        
        let decoded = try JSONDecoder().decode(KeyedArchiveSerializable<NSError>.self, from: data).wrappedValue
        XCTAssertEqual(decoded.domain, "D")
        XCTAssertEqual(decoded.code, 10)
        XCTAssertEqual(decoded.userInfo[NSDebugDescriptionErrorKey] as? String, "test")
    }
}

class DictionaryCoderTests: XCTestCase {
    struct Foo: Equatable, Codable {
        var a = 10
        var b = "qwerty"
        var c = [1, 2, 3]
        var d = ["q": 1, "w": 2]
        var e: [Foo] = []
    }
    
    func test() throws {
        var value = Foo()
        value.e = [Foo(), Foo()]
        
        let dict = try DictionaryCoder().encode(value, as: [String: Any].self)
        XCTAssertEqual(dict["a"] as? Int, value.a)
        XCTAssertEqual(dict["b"] as? String, value.b)
        XCTAssertEqual(dict["c"] as? [Int], value.c)
        XCTAssertEqual(dict["d"] as? [String: Int], value.d)
        XCTAssertEqual((dict["e"] as? [[String: Any]])?.count, value.e.count)
        
        let decoded = try DictionaryCoder().decode(Foo.self, from: dict)
        XCTAssertEqual(decoded, value)
    }
}
