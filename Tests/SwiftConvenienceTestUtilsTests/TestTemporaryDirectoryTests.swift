import SwiftConvenienceTestUtils

import XCTest


class TestTemporaryDirectoryTests: XCTestCase {
    let testTempDir = TestTemporaryDirectory(prefix: "MHT-Tests")

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        try testTempDir.setUp()
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try testTempDir.tearDown()
        try super.tearDownWithError()
    }
    
    func test_multipleDirectories() throws {
        let dirs = [nil, nil, "prefix", "prefix"]
            .map(TestTemporaryDirectory.init)
        try dirs.forEach { try $0.setUp() }
        try dirs.forEach { try $0.tearDown() }
    }
    
    func test_manualSetupTearDown() throws {
        let fm = FileManager.default
        let tempDir = TestTemporaryDirectory()
        
        XCTAssertFalse(fm.fileExists(at: tempDir.url))
        try tempDir.setUp()
        XCTAssertTrue(fm.directoryExists(at: tempDir.url))
        
        let file = try tempDir.createFile("content")
        XCTAssertTrue(fm.fileExists(at: file))
        let subdir = try tempDir.createSubdirectory("subdir")
        XCTAssertTrue(fm.directoryExists(at: subdir))
        
        try tempDir.tearDown()
        
        XCTAssertFalse(fm.fileExists(at: file))
        XCTAssertFalse(fm.directoryExists(at: subdir))
        XCTAssertFalse(fm.directoryExists(at: tempDir.url))
    }

    func test_createSubdirectory() throws {
        // simple subpath
        let simpleSubdir = try testTempDir.createSubdirectory("Subdir")
        XCTAssertEqual(simpleSubdir.lastPathComponent, "Subdir")
        XCTAssertTrue(FileManager.default.directoryExists(at: simpleSubdir))

        // complex subpath
        let complexSubdir = try testTempDir.createSubdirectory("Subdir2/Subsubdir")
        XCTAssertEqual(complexSubdir.lastPathComponent, "Subsubdir")
        XCTAssertEqual(complexSubdir.deletingLastPathComponent().lastPathComponent, "Subdir2")
        XCTAssertTrue(FileManager.default.directoryExists(at: complexSubdir))
    }

    func test_createFile() throws {
        let emptyFile = try testTempDir.createFile("Empty.txt")
        XCTAssertTrue(FileManager.default.fileExists(at: emptyFile))
        XCTAssertEqual(try Data(contentsOf: emptyFile), Data())
        
        // Error if trying to create file that already exists.
        XCTAssertThrowsError(try testTempDir.createFile("Empty.txt"))
        
        let content = Data("content".utf8)
        let nonEmptyFile = try testTempDir.createFile("NonEmpty.txt", content: content)
        XCTAssertTrue(FileManager.default.fileExists(at: nonEmptyFile))
        XCTAssertEqual(try Data(contentsOf: nonEmptyFile), content)
    }
}
