import SpellbookFoundation
import SpellbookTestUtils

import XCTest

class FileEnumeratorTests: XCTestCase {
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
    
    func test_enumerateFiles() throws {
        var expectedFiles = [tempDir.location]
        try expectedFiles.append(tempDir.createFile(name: "file1", content: Data()))
        try expectedFiles.append(tempDir.createFile(name: "file2", content: Data()))
        try expectedFiles.append(tempDir.directory(name: "subdir").setUp().location)
        try expectedFiles.append(tempDir.createFile(name: "subdir/file3", content: Data()))
        try expectedFiles.append(tempDir.directory(name: "subdir/nested").setUp().location)
        try expectedFiles.append(tempDir.createFile(name: "subdir/nested/file4", content: Data()))
        
        let enumeratedFiles = Array(FileEnumerator(tempDir.location))
        XCTAssertEqual(
            Set(enumeratedFiles.map { $0.resolvingSymlinksInPath() }),
            Set(expectedFiles.map { $0.resolvingSymlinksInPath() })
        )
    }
    
    func test_enumerateFiles_ofTypes() throws {
        var expectedFiles: [URL] = []
        try expectedFiles.append(tempDir.createFile(name: "file1", content: Data()))
        try expectedFiles.append(tempDir.createFile(name: "file2", content: Data()))
        try tempDir.directory(name: "subdir").setUp()
        try expectedFiles.append(tempDir.createFile(name: "subdir/file3", content: Data()))
        try tempDir.directory(name: "subdir/nested").setUp()
        try expectedFiles.append(tempDir.createFile(name: "subdir/nested/file4", content: Data()))
        
        let enumeratedFiles = Array(FileEnumerator(types: [.regular], tempDir.location))
        XCTAssertEqual(
            Set(enumeratedFiles.map { $0.resolvingSymlinksInPath() }),
            Set(expectedFiles.map { $0.resolvingSymlinksInPath() })
        )
    }
    
    func test_enumerateFiles_filter() throws {
        var expectedFiles = [tempDir.location]
        try expectedFiles.append(tempDir.createFile(name: "file1", content: Data()))
        
        try tempDir.directory("subdir").setUp()
        try expectedFiles.append(tempDir.directory("subdir/folder1").setUp().location)
        try expectedFiles.append(tempDir.createFile(name: "subdir/file3", content: Data()))
        
        try tempDir.directory("subdir/nested").setUp()
        _ = try tempDir.createFile(name: "subdir/nested/file4", content: Data())
        
        let enumerator = FileEnumerator(tempDir.location)
        enumerator.locationFilter = {
            switch $0.lastPathComponent {
            case "subdir":
                return .skip
            case "nested":
                return .skipRecursive
            default:
                return .proceed
            }
        }
        let enumeratedFiles = Array(enumerator)
        XCTAssertEqual(
            Set(enumeratedFiles.map { $0.resolvingSymlinksInPath() }),
            Set(expectedFiles.map { $0.resolvingSymlinksInPath() })
        )
    }
}
