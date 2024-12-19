import SpellbookFoundation
import SpellbookTestUtils

import XCTest

class FileManagerExtensionsTests: XCTestCase {
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
    
    func test_fileExistsAt() throws {
        let file = try tempDir.createFile(name: "testfile", content: Data())
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(FileManager.default.fileExists(at: file))
    }
    
    func test_directoryExistsAt() throws {
        let directory = tempDir.location
        let file = try tempDir.createFile(name: "testfile", content: Data())
        
        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory))
        XCTAssertFalse(isDirectory.boolValue)
        XCTAssertFalse(FileManager.default.directoryExists(at: file))
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertTrue(FileManager.default.directoryExists(at: directory))
    }
    
    func test_xattr() throws {
        let file = try tempDir.createFile(name: "file", content: Data())
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
    
    func test_uniqueFile() {
        let fm = FileManager.default
        func createFile(_ name: String) -> Bool {
            fm.createFile(atPath: tempDir.location.appendingPathComponent(name).path, contents: .random(20))
        }
        
        XCTAssertEqual(fm.uniqueFile("test.foo", in: tempDir.location).lastPathComponent, "test.foo")
        // Ensure it is not created.
        XCTAssertEqual(fm.uniqueFile("test.foo", in: tempDir.location).lastPathComponent, "test.foo")
        
        XCTAssertTrue(createFile("test.foo"))
        XCTAssertEqual(fm.uniqueFile("test.foo", in: tempDir.location).lastPathComponent, "test_1.foo")
        
        XCTAssertTrue(createFile("test.foo.bar"))
        XCTAssertEqual(fm.uniqueFile("test.foo.bar", in: tempDir.location).lastPathComponent, "test.foo_1.bar")
        
        XCTAssertEqual(fm.uniqueFile("test", in: tempDir.location).lastPathComponent, "test")
        XCTAssertTrue(createFile("test"))
        XCTAssertTrue(createFile("test_1"))
        XCTAssertTrue(createFile("test_3"))
        XCTAssertEqual(fm.uniqueFile("test", in: tempDir.location).lastPathComponent, "test_2")
        
        XCTAssertEqual(fm.uniqueFile("dir/", in: tempDir.location).lastPathComponent, "dir")
        XCTAssertTrue(createFile("dir"))
        XCTAssertEqual(fm.uniqueFile("dir/", in: tempDir.location).lastPathComponent, "dir_1")
    }
}
