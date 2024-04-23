import SpellbookFoundation

import XCTest

class TemporaryDirectoryTests: XCTestCase {
    let tempDir = TemporaryDirectory.bundle
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        try tempDir.setUp()
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try tempDir.tearDown()
        try super.tearDownWithError()
    }
    
    func test_multipleDirectories() throws {
        let dirs = [nil, nil, "prefix", "prefix"]
            .map { TemporaryDirectory(prefix: $0) }
        try dirs.forEach { try $0.setUp() }
        try dirs.forEach { try $0.tearDown() }
    }
    
    func test_manualSetupTearDown() throws {
        let fm = FileManager.default
        let tempDir = TemporaryDirectory()
        
        XCTAssertFalse(fm.fileExists(at: tempDir.location))
        try tempDir.setUp()
        XCTAssertTrue(fm.directoryExists(at: tempDir.location))
        
        let file = try tempDir.createFile(name: "content", content: Data())
        XCTAssertTrue(fm.fileExists(at: file))
        let subdir = try tempDir.directory("subdir").setUp()
        XCTAssertTrue(fm.directoryExists(at: subdir.location))
        
        try tempDir.tearDown()
        
        XCTAssertFalse(fm.fileExists(at: file))
        XCTAssertFalse(fm.directoryExists(at: subdir.location))
        XCTAssertFalse(fm.directoryExists(at: tempDir.location))
    }
    
    func test_createSubdirectory() throws {
        // simple subpath
        let simpleSubdir = try tempDir.directory("Subdir").setUp()
        XCTAssertEqual(simpleSubdir.location.lastPathComponent, "Subdir")
        XCTAssertTrue(FileManager.default.directoryExists(at: simpleSubdir.location))
        
        // complex subpath
        let complexSubdir = try tempDir.directory("Subdir2/Subsubdir").setUp()
        XCTAssertEqual(complexSubdir.location.lastPathComponent, "Subsubdir")
        XCTAssertEqual(complexSubdir.location.deletingLastPathComponent().lastPathComponent, "Subdir2")
        XCTAssertTrue(FileManager.default.directoryExists(at: complexSubdir.location))
    }
    
    func test_createFile() throws {
        let emptyFile = try tempDir.createFile(name: "Dup.txt", content: "q".utf8Data)
        XCTAssertEqual(try Data(contentsOf: emptyFile), "q".utf8Data)
        
        // Overwrite file if trying to create file that already exists.
        XCTAssertEqual(try tempDir.createFile(name: "Dup.txt", content: "w".utf8Data), emptyFile)
        XCTAssertEqual(try Data(contentsOf: emptyFile), "w".utf8Data)
        
        let content = Data("content".utf8)
        let nonEmptyFile = try tempDir.createFile(name: "NonEmpty.txt", content: content)
        XCTAssertTrue(FileManager.default.fileExists(at: nonEmptyFile))
        XCTAssertEqual(try Data(contentsOf: nonEmptyFile), content)
    }
}
