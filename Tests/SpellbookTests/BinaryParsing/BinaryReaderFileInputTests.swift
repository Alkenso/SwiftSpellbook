import SpellbookBinaryParsing
import SpellbookFoundation

import XCTest

class BinaryReaderFileInputTests: XCTestCase {
    private let tempDir = TemporaryDirectory()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try tempDir.setUp()
    }
    
    override func tearDownWithError() throws {
        try tempDir.tearDown()
        try super.tearDownWithError()
    }
    
    func test_sequentialAndRandomReads() throws {
        let file = try tempDir.createFile(content: Data([0x01, 0x02, 0x03, 0x04, 0xaa, 0xbb]))
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        let input = try BinaryReaderFileInput(fileHandle: handle)
        var reader = BinaryReader(input)
        
        XCTAssertEqual(try reader.size(), 6)
        XCTAssertEqual(try reader.read(count: 2), Data([0x01, 0x02]))
        XCTAssertEqual(try reader.size(), 6)
        XCTAssertEqual(try handle.offset(), 2)
        XCTAssertEqual(try reader.read(count: 2), Data([0x03, 0x04]))
        XCTAssertEqual(try reader.peekUInt8(offset: 1), 0x02)
        XCTAssertEqual(try reader.read(count: 2), Data([0xaa, 0xbb]))
        
        reader.reset()
        XCTAssertEqual(try reader.readUInt8(), 0x01)
        var copy = reader
        XCTAssertEqual(try copy.read(count: 2), Data([0x02, 0x03]))
        XCTAssertEqual(try reader.readUInt8(), 0x02)
    }
    
    func test_urlInitializer() throws {
        let file = try tempDir.createFile(content: Data([0x01, 0x02, 0x03]))
        let input = try BinaryReaderFileInput(url: file)
        var reader = BinaryReader(input)
        
        XCTAssertEqual(try reader.size(), 3)
        XCTAssertEqual(try reader.read(maxCount: 10), Data([0x01, 0x02, 0x03]))
        XCTAssertThrowsError(try BinaryReaderFileInput(url: file.appendingPathExtension("missing")))
    }
    
    func test_invalidRanges() throws {
        let file = try tempDir.createFile(content: Data([0x01, 0x02]))
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        let input = try BinaryReaderFileInput(fileHandle: handle)
        var buffer = [UInt8](repeating: 0, count: 2)
        
        for offset in [-1, 1, 2, 3, Int.max] {
            XCTAssertThrowsError(try buffer.withUnsafeMutableBufferPointer {
                try input.readBytes(to: $0, offset: offset)
            }) {
                guard case BinaryParsingError.outOfRange = $0 else {
                    return XCTFail("Unexpected error: \($0)")
                }
            }
        }
        
        try buffer.withUnsafeMutableBufferPointer {
            try input.readBytes(to: $0, offset: 0)
        }
        XCTAssertEqual(buffer, [0x01, 0x02])
    }
    
    func test_emptyReadAtEndOfFile() throws {
        let file = try tempDir.createFile(content: Data())
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        let input = try BinaryReaderFileInput(fileHandle: handle)
        var reader = BinaryReader(input)
        
        XCTAssertEqual(try reader.size(), 0)
        XCTAssertEqual(try reader.read(count: 0), Data())
        XCTAssertThrowsError(try reader.readUInt8())
    }
    
    func test_shortReadAndRecovery() throws {
        let file = try tempDir.createFile(content: Data([0x01, 0x02, 0x03, 0x04]))
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        let input = try BinaryReaderFileInput(fileHandle: handle)
        let writer = try FileHandle(forWritingTo: file)
        defer { try? writer.close() }
        try writer.truncate(atOffset: 2)
        var buffer = [UInt8](repeating: 0, count: 4)
        
        XCTAssertThrowsError(try buffer.withUnsafeMutableBufferPointer {
            try input.readBytes(to: $0, offset: 0)
        }) {
            guard case BinaryParsingError.outOfRange = $0 else {
                return XCTFail("Unexpected error: \($0)")
            }
        }
        
        var reader = BinaryReader(input)
        XCTAssertEqual(try reader.read(count: 2), Data([0x01, 0x02]))
    }
}
