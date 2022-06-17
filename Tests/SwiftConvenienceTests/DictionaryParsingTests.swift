import SwiftConvenience

import XCTest

class DictionaryReaderTests: XCTestCase {
    func test_codingPath() throws {
        let person: [String: Any] = [
            "name": "Bob",
            "address": [
                "city": "Miami",
                "zip": 12345,
            ],
            "children": [
                ["name": "Volodymyr", "age": 10],
                ["name": "Julia", "age": 6],
            ],
        ]
        var reader = DictionaryReader(person)
        reader.contextDescription = "Parsing person properties from dict \(person)"
        
        // read
        XCTAssertNoThrow(try reader.read(key: "name"))
        XCTAssertThrowsError(try reader.read(key: "name2"))
        
        // read + convert
        XCTAssertEqual(try reader.read(key: "name", as: String.self), "Bob")
        XCTAssertThrowsError(try reader.read(key: "name", as: Int.self))
        XCTAssertThrowsError(try reader.read(key: "name") { $0 as? Int })
        
        // codingPath
        XCTAssertEqual(try reader.read(codingPath: ["address", "city"], as: String.self), "Miami")
        XCTAssertThrowsError(try reader.read(codingPath: ["address", "city2"], as: String.self))
        
        XCTAssertEqual(try reader.read(codingPath: ["children", .index(0), "age"], as: Int.self), 10)
        XCTAssertEqual(try reader.read(codingPath: ["children", .index(1), "age"], as: Int.self), 6)
        XCTAssertEqual(try reader.read(codingPath: ["children", .index(.max), "age"], as: Int.self), 6)
        XCTAssertEqual(try reader.read(codingPath: ["children", .index(.max), "age"], as: Int.self), 6)
        XCTAssertThrowsError(try reader.read(codingPath: ["children", .index(123), "age"], as: Int.self))
        
        // dotPath
        XCTAssertEqual(try reader.read(dotPath: "address.city", as: String.self), "Miami")
        XCTAssertThrowsError(try reader.read(dotPath: "address.city2", as: String.self))
        
        XCTAssertEqual(try reader.read(dotPath: "children.[0].age", as: Int.self), 10)
        XCTAssertEqual(try reader.read(dotPath: "children.[1].age", as: Int.self), 6)
        XCTAssertEqual(try reader.read(dotPath: "children.[*].age", as: Int.self), 6)
        XCTAssertEqual(try reader.read(dotPath: "children.[*].age", as: Int.self), 6)
        XCTAssertThrowsError(try reader.read(dotPath: "children.[123].age", as: Int.self))
    }
    
    func test_errorTypes() throws {
        // CommonError.invalidArgument
        do {
            _ = try DictionaryReader([:]).read(codingPath: [], as: String.self)
            XCTFail("Read should fail")
        } catch let error as CommonError {
            XCTAssertEqual(error.code, .invalidArgument)
        }
        do {
            _ = try DictionaryReader([:]).read(dotPath: "", as: String.self)
            XCTFail("Read should fail")
        } catch let error as CommonError {
            XCTAssertEqual(error.code, .invalidArgument)
        }
        
        // DecodingError.typeMismatch
        do {
            _ = try DictionaryReader(["key": "value"]).read(codingPath: ["key"], as: Int.self)
            XCTFail("Read should fail")
        } catch let error as DecodingError {
            if case .typeMismatch = error {} else {
                XCTFail("Error must be DecodingError.typeMismatch, but got \(error)")
            }
        }
        do {
            _ = try DictionaryReader(["key": "value"]).read(dotPath: "key", as: Int.self)
            XCTFail("Read should fail")
        } catch let error as DecodingError {
            if case .typeMismatch = error {} else {
                XCTFail("Error must be DecodingError.typeMismatch, but got \(error)")
            }
        }
        
        // DecodingError.keyNotFound
        do {
            _ = try DictionaryReader(["key": "value"]).read(codingPath: ["key_2"], as: Int.self)
            XCTFail("Read should fail")
        } catch let error as DecodingError {
            if case .keyNotFound = error {} else {
                XCTFail("Error must be DecodingError.keyNotFound, but got \(error)")
            }
        }
        do {
            _ = try DictionaryReader(["key": "value"]).read(dotPath: "key_2", as: Int.self)
            XCTFail("Read should fail")
        } catch let error as DecodingError {
            if case .keyNotFound = error {} else {
                XCTFail("Error must be DecodingError.keyNotFound, but got \(error)")
            }
        }
    }
}

class DictionaryWriterTests: XCTestCase {
    func codingPath() throws {
        var person: [String: Any] = [
            "name": "Bob",
            "address": [
                "city": "Miami",
                "zip": 12345,
            ],
            "children": [
                ["name": "Volodymyr", "age": 10],
                ["name": "Julia", "age": 6],
            ],
        ]
        
        var writer = DictionaryWriter(person) { person = $0 }
        
        // replace value
        XCTAssertNoThrow(try writer.insert(value: "Jane", codingPath: ["name"]))
        XCTAssertEqual(person["name"] as? String, "Jane")
        
        // replace nested value
        let agePath: [DictionaryCodingKey] = ["children", .index(1), "age"]
        XCTAssertNoThrow(try writer.insert(value: 12, codingPath: agePath))
        XCTAssertEqual(person[codingPath: agePath] as? Int, 12)
        
        // insert value
        let parentPath = "parents.[0].name"
        XCTAssertNoThrow(try writer.insert(value: "John", dotPath: parentPath))
        XCTAssertEqual(person[dotPath: parentPath] as? String, "John")
    }
    
    func test_errorTypes() throws {
        // CommonError.invalidArgument
        do {
            var writer = DictionaryWriter([:])
            _ = try writer.insert(value: 10, codingPath: [])
            XCTFail("Insert should fail")
        } catch let error as CommonError {
            XCTAssertEqual(error.code, .invalidArgument)
        }
        do {
            var writer = DictionaryWriter([:])
            _ = try writer.insert(value: 10, dotPath: "")
            XCTFail("Insert should fail")
        } catch let error as CommonError {
            XCTAssertEqual(error.code, .invalidArgument)
        }
        
        // DecodingError.typeMismatch
        do {
            var writer = DictionaryWriter(["key": "value"])
            _ = try writer.insert(value: 10, codingPath: ["key", "value", "q"])
            XCTFail("Insert should fail")
        } catch let error as DecodingError {
            if case .typeMismatch = error {} else {
                XCTFail("Error must be DecodingError.typeMismatch, but got \(error)")
            }
        }
        do {
            var writer = DictionaryWriter(["key": "value"])
            _ = try writer.insert(value: 10, dotPath: "key.value.[0]")
            XCTFail("Insert should fail")
        } catch let error as DecodingError {
            if case .typeMismatch = error {} else {
                XCTFail("Error must be DecodingError.typeMismatch, but got \(error)")
            }
        }
        
        // DecodingError.keyNotFound
        do {
            var writer = DictionaryWriter(["key": [1, 2, 3]])
            _ = try writer.insert(value: 10, codingPath: ["key", .index(20)])
            XCTFail("Insert should fail")
        } catch let error as DecodingError {
            if case .keyNotFound = error {} else {
                XCTFail("Error must be DecodingError.keyNotFound, but got \(error)")
            }
        }
        do {
            var writer = DictionaryWriter(["key": [1, 2, 3]])
            _ = try writer.insert(value: 10, dotPath: "key.[20]")
            XCTFail("Insert should fail")
        } catch let error as DecodingError {
            if case .keyNotFound = error {} else {
                XCTFail("Error must be DecodingError.keyNotFound, but got \(error)")
            }
        }
    }
}
