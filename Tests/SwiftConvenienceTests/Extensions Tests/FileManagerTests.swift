import SwiftConvenience
import SwiftConvenienceTestUtils

import XCTest


class FileManagerExtensionsTests: XCTestCase {
    let tempDir = TestTemporaryDirectory(prefix: "MHT-Tests")

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        try tempDir.setUp()
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try tempDir.tearDown()
        try super.tearDownWithError()
    }
    
    func test_fileExistsAt() throws {
        let file = try tempDir.createFile("testfile")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(FileManager.default.fileExists(at: file))
    }
    
    func test_directoryExistsAt() throws {
        let directory = tempDir.url
        let file = try tempDir.createFile("testfile")
        
        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory))
        XCTAssertFalse(isDirectory.boolValue)
        XCTAssertFalse(FileManager.default.directoryExists(at: file))
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertTrue(FileManager.default.directoryExists(at: directory))
    }
    
    func test_xattr() throws {
        let file = try tempDir.createFile("file")
        XCTAssertEqual(try FileManager.default.listXattr(at: file), [])
        XCTAssertThrowsError(try FileManager.default.xattr(at: file, name: "xa"))
        XCTAssertThrowsError(try FileManager.default.removeXattr(at: file, name: "xa"))
        
        let value1 = Data(pod: 100500)
        let value2 = Data("some value".utf8)
        XCTAssertNoThrow(try FileManager.default.setXattr(at: file, name: "xa1", value: value1))
        XCTAssertNoThrow(try FileManager.default.setXattr(at: file, name: "xa2", value: value2))
        
        let attrs = try FileManager.default.listXattr(at: file)
        XCTAssertTrue(attrs.contains("xa1"))
        XCTAssertTrue(attrs.contains("xa2"))
        
        XCTAssertEqual(try FileManager.default.xattr(at: file, name: "xa1"), value1)
        XCTAssertEqual(try FileManager.default.xattr(at: file, name: "xa2"), value2)
        
        try FileManager.default.removeXattr(at: file, name: "xa1")
        XCTAssertEqual(try FileManager.default.listXattr(at: file), ["xa2"])
    }
}
