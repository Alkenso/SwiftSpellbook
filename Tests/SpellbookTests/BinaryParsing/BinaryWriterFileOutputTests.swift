import SpellbookBinaryParsing
import SpellbookFoundation

import XCTest

class BinaryWriterFileOutputTests: XCTestCase {
    private let tempDir = TemporaryDirectory()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try tempDir.setUp()
    }
    
    override func tearDownWithError() throws {
        try tempDir.tearDown()
        try super.tearDownWithError()
    }
    
    func test_sequentialAndRandomWrites() throws {
        let file = try tempDir.createFile(content: Data())
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        let output = try BinaryWriterFileOutput(fileHandle: handle)
        var writer = BinaryWriter(output)
        
        XCTAssertEqual(try writer.size(), 0)
        try writer.append(Data([0x01, 0x02]))
        XCTAssertEqual(try writer.size(), 2)
        XCTAssertEqual(try handle.offset(), 2)
        try writer.append(Data([0x03, 0x04]))
        try writer.writeUInt8(0xaa, at: 1)
        XCTAssertEqual(try writer.size(), 4)
        try writer.appendUInt8(0xbb)
        XCTAssertEqual(try writer.size(), 5)
        XCTAssertEqual(try Data(contentsOf: file), Data([0x01, 0xaa, 0x03, 0x04, 0xbb]))
        
        writer.reset()
        var copy = writer
        try copy.append(Data([0xcc, 0xdd]))
        try writer.appendUInt8(0xff)
        XCTAssertEqual(try writer.size(), 5)
        XCTAssertEqual(try Data(contentsOf: file), Data([0xff, 0xdd, 0x03, 0x04, 0xbb]))
    }
    
    func test_urlInitializer() throws {
        let file = try tempDir.createFile(content: Data([0x01, 0x02, 0x03]))
        let output = try BinaryWriterFileOutput(url: file)
        var writer = BinaryWriter(output)
        
        XCTAssertEqual(try writer.size(), 3)
        try writer.appendUInt8(0xaa)
        XCTAssertEqual(try writer.size(), 3)
        XCTAssertEqual(try Data(contentsOf: file), Data([0xaa, 0x02, 0x03]))
        XCTAssertThrowsError(try BinaryWriterFileOutput(url: file.appendingPathExtension("missing")))
    }
    
    func test_writeBeyondEndOfFile() throws {
        let file = try tempDir.createFile(content: Data([0x01, 0x02]))
        let output = try BinaryWriterFileOutput(url: file)
        let writer = BinaryWriter(output)
        
        try writer.write(Data([0xaa, 0xbb]), at: 4)
        XCTAssertEqual(try writer.size(), 6)
        XCTAssertEqual(try Data(contentsOf: file), Data([0x01, 0x02, 0x00, 0x00, 0xaa, 0xbb]))
    }
    
    func test_emptyWrites() throws {
        let file = try tempDir.createFile(content: Data())
        let output = try BinaryWriterFileOutput(url: file)
        var writer = BinaryWriter(output)
        
        try writer.append(Data())
        XCTAssertEqual(try writer.size(), 0)
        try writer.writeZeroes(3, at: 0)
        XCTAssertEqual(try writer.size(), 3)
        XCTAssertEqual(try Data(contentsOf: file), Data([0x00, 0x00, 0x00]))
        try writer.appendUInt8(0xaa)
        XCTAssertEqual(try writer.size(), 3)
        XCTAssertEqual(try Data(contentsOf: file), Data([0xaa, 0x00, 0x00]))
    }
    
    func test_invalidRanges() throws {
        let file = try tempDir.createFile(content: Data([0x01, 0x02]))
        let output = try BinaryWriterFileOutput(url: file)
        let writer = BinaryWriter(output)
        
        for offset in [-1, Int.max] {
            XCTAssertThrowsError(try writer.write(Data([0xaa, 0xbb]), at: offset)) {
                guard case BinaryParsingError.outOfRange = $0 else {
                    return XCTFail("Unexpected error: \($0)")
                }
            }
        }
        
        XCTAssertEqual(try writer.size(), 2)
        XCTAssertEqual(try Data(contentsOf: file), Data([0x01, 0x02]))
        try writer.writeUInt8(0xaa, at: 0)
        XCTAssertEqual(try Data(contentsOf: file), Data([0xaa, 0x02]))
    }
}
