import SpellbookFoundation
import SpellbookTestUtils

import XCTest

class FileStoreTests: XCTestCase {
    let tempDir = TestTemporaryDirectory(prefix: "SBTests")
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        try tempDir.setUp()
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try tempDir.tearDown()
        try super.tearDownWithError()
    }
    
    func test_standard() throws {
        let url = tempDir.url.appendingPathComponent("test.file")
        let store = FileStore.standard
        XCTAssertThrowsError(try store.read(from: url))
        XCTAssertEqual(try store.read(from: url, default: Data(pod: 100500)), Data(pod: 100500))
        
        let subdir = tempDir.url.appendingPathComponent("subdir")
        let fileInSubdir = subdir.appendingPathComponent("test.file")
        XCTAssertFalse(FileManager.default.fileExists(at: subdir))
        XCTAssertThrowsError(try store.write(Data(pod: 100500), to: fileInSubdir))
        XCTAssertFalse(FileManager.default.fileExists(at: subdir))
        XCTAssertNoThrow(try store.write(Data(pod: 100500), to: fileInSubdir, createDirectories: true))
        XCTAssertTrue(FileManager.default.fileExists(at: subdir))
        XCTAssertTrue(FileManager.default.fileExists(at: fileInSubdir))
    }
    
    func test_exact() throws {
        let url = tempDir.url.appendingPathComponent("test.file")
        let store = FileStore.standard.exact(url)
        XCTAssertThrowsError(try store.read())
        XCTAssertEqual(try store.read(default: Data(pod: 20)), Data(pod: 20))
        
        let storeWithDefault = FileStore.standard.exact(url, default: Data(pod: 10))
        XCTAssertEqual(try storeWithDefault.read(), Data(pod: 10))
        XCTAssertEqual(try storeWithDefault.read(default: Data(pod: 20)), Data(pod: 20))
        
        XCTAssertFalse(FileManager.default.fileExists(at: url))
    }
    
    func test_codable() throws {
        let url = tempDir.url.appendingPathComponent("test.file")
        let store = FileStore.standard.codable(Int.self, using: .json()).exact(url)
        XCTAssertThrowsError(try store.read())
        XCTAssertEqual(try store.read(default: 20), 20)
        XCTAssertFalse(FileManager.default.fileExists(at: url))
        
        XCTAssertNoThrow(try store.write(10))
        XCTAssertEqual(try store.read(default: 20), 10)
        XCTAssertTrue(FileManager.default.fileExists(at: url))
    }
}
