import SwiftConvenience
import SwiftConvenienceTestUtils

import XCTest


class BinaryReaderTests: XCTestCase {
    func test() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04, 0xaa, 0xbb, 0xcc, 0xdd])
        var reader = BinaryReader(data: data)
        XCTAssertEqual(try reader.size(), data.count)
        
        XCTAssertEqual(try reader.read() as UInt32, 0x04030201)
        XCTAssertEqual(try reader.read(count: 2), Data([0xaa, 0xbb]))
        XCTAssertEqual(try reader.read(maxCount: 10), Data([0xcc, 0xdd]))
        
        XCTAssertEqual(try reader.peekInt8(offset: 2), 0x03)
        XCTAssertEqual(try reader.peek(at: Range(offset: 1, length: 3)), Data([0x02, 0x03, 0x04]))
    }
}


class BinaryWriterTests: XCTestCase {
    func test() throws {
        let output = DataBinaryWriterOutput()
        var writer = BinaryWriter(output)
        
        try writer.append(Data([0x00, 0x01]))
        XCTAssertEqual(output.data, Data([0x00, 0x01]))
        
        try writer.append(Data([0x02]))
        XCTAssertEqual(output.data, Data([0x00, 0x01, 0x02]))
        
        try writer.appendZeroes(2)
        XCTAssertEqual(output.data, Data([0x00, 0x01, 0x02, 0x00, 0x00]))
        
        try writer.write(Data([0xff, 0xfa]), at: 2)
        XCTAssertEqual(output.data, Data([0x00, 0x01, 0xff, 0xfa, 0x00]))
        
        try writer.writeUInt8(0x11, at: 4)
        XCTAssertEqual(output.data, Data([0x00, 0x01, 0xff, 0xfa, 0x11]))
        
        //  Override and extend
        try writer.write(Data([0xaa, 0xa1, 0xa2, 0xa3]), at: 3)
        XCTAssertEqual(output.data, Data([0x00, 0x01, 0xff, 0xaa, 0xa1, 0xa2, 0xa3]))
    }
}
