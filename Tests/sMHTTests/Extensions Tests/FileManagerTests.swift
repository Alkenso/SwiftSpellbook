import sMHT
import sMHTTestUtils

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
}
