import SpellbookFoundation

import XCTest

class PODTests: XCTestCase {
    func testBitwiseCopyableDataConversions() {
        let value = PODValue(number: 0x04030201, tag: 0x05)
        let bytes = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        XCTAssertEqual(Data(pod: value), bytes)
        XCTAssertEqual(bytes.pod(exactly: PODValue.self), value)
        XCTAssertNil(bytes.dropLast().pod(exactly: PODValue.self))
        XCTAssertEqual((bytes + Data([0xff])).pod(adopting: PODValue.self), value)
        XCTAssertEqual(bytes.dropLast().pod(adopting: PODValue.self), PODValue(number: 0x04030201, tag: 0))
    }

    func testPODCodableUsesSingleDataValue() throws {
        let value = PODValue(number: 0x04030201, tag: 0x05)
        let encoded = try JSONEncoder().encode(value)

        XCTAssertEqual(try JSONDecoder().decode(Data.self, from: encoded), Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        XCTAssertEqual(try JSONDecoder().decode(PODValue.self, from: encoded), value)
    }

    func testPODCodableProvidesBitwiseCopyableConstraint() {
        func bytes<T: PODCodable & BitwiseCopyable>(of value: T) -> Data {
            Data(pod: value)
        }

        XCTAssertEqual(bytes(of: PODValue(number: 0x04030201, tag: 0x05)), Data([0x01, 0x02, 0x03, 0x04, 0x05]))
    }

    func testPODCodableRejectsIncorrectDataSize() throws {
        for bytes in [Data([0x01, 0x02, 0x03, 0x04]), Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])] {
            let encoded = try JSONEncoder().encode(bytes)

            XCTAssertThrowsError(try JSONDecoder().decode(PODValue.self, from: encoded)) { error in
                guard case DecodingError.dataCorrupted = error else {
                    return XCTFail("Expected dataCorrupted, got \(error)")
                }
            }
        }
    }

    func testEmptyPODValue() throws {
        let value = EmptyPODValue()
        let encoded = try JSONEncoder().encode(value)

        XCTAssertEqual(Data(pod: value), Data())
        XCTAssertEqual(Data().pod(exactly: EmptyPODValue.self), value)
        XCTAssertEqual(Data().pod(adopting: EmptyPODValue.self), value)
        XCTAssertEqual(try JSONDecoder().decode(Data.self, from: encoded), Data())
        XCTAssertEqual(try JSONDecoder().decode(EmptyPODValue.self, from: encoded), value)
    }

    func testImportedCValuePreservesRawCoding() throws {
        let value = timespec(tv_sec: 1, tv_nsec: 2)
        let encoded = try JSONEncoder().encode(value)

        XCTAssertEqual(
            try JSONDecoder().decode(Data.self, from: encoded),
            Data([1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0])
        )
        let decoded = try JSONDecoder().decode(timespec.self, from: encoded)
        XCTAssertEqual(decoded.tv_sec, 1)
        XCTAssertEqual(decoded.tv_nsec, 2)
    }

    func testImportedCCodingUsesExactDataSize() throws {
        func check<T: Codable & BitwiseCopyable>(_ type: T.Type) throws {
            let count = MemoryLayout<T>.size
            let encoded = try JSONEncoder().encode(Data(repeating: 0, count: count))
            let value = try JSONDecoder().decode(type, from: encoded)
            let recoded = try JSONEncoder().encode(value)
            XCTAssertEqual(try JSONDecoder().decode(Data.self, from: recoded).count, count)

            let truncated = try JSONEncoder().encode(Data(repeating: 0, count: count - 1))
            XCTAssertThrowsError(try JSONDecoder().decode(type, from: truncated))
        }

        try check(timespec.self)
        try check(fsid_t.self)
        try check(attrlist.self)
        try check(attribute_set.self)
        try check(attrreference.self)
        try check(diskextent.self)
        try check(stat.self)
        try check(statfs.self)
        try check(timeval.self)
        #if os(macOS)
        try check(audit_token_t.self)
        #endif
    }
}

private struct PODValue: SafePOD, Equatable {
    var number: UInt32
    var tag: UInt8
}

private struct EmptyPODValue: PODCodable, Equatable {}
