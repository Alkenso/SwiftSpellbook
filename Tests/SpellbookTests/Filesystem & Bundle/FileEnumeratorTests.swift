import SpellbookFoundation
import SpellbookTestUtils

import XCTest

class FileEnumeratorTests: XCTestCase {
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
    
    func test_enumerateFiles() throws {
        var expectedFiles = [tempDir.url]
        try expectedFiles.append(tempDir.createFile("file1"))
        try expectedFiles.append(tempDir.createFile("file2"))
        try expectedFiles.append(tempDir.createSubdirectory("subdir"))
        try expectedFiles.append(tempDir.createFile("subdir/file3"))
        try expectedFiles.append(tempDir.createSubdirectory("subdir/nested"))
        try expectedFiles.append(tempDir.createFile("subdir/nested/file4"))
        
        let enumeratedFiles = Array(FileEnumerator(tempDir.url))
        XCTAssertEqual(
            Set(enumeratedFiles.map { $0.resolvingSymlinksInPath() }),
            Set(expectedFiles.map { $0.resolvingSymlinksInPath() })
        )
    }
    
    func test_enumerateFiles_ofTypes() throws {
        var expectedFiles: [URL] = []
        try expectedFiles.append(tempDir.createFile("file1"))
        try expectedFiles.append(tempDir.createFile("file2"))
        _ = try tempDir.createSubdirectory("subdir")
        try expectedFiles.append(tempDir.createFile("subdir/file3"))
        _ = try tempDir.createSubdirectory("subdir/nested")
        try expectedFiles.append(tempDir.createFile("subdir/nested/file4"))
        
        let enumeratedFiles = Array(FileEnumerator(types: [.regular], tempDir.url))
        XCTAssertEqual(
            Set(enumeratedFiles.map { $0.resolvingSymlinksInPath() }),
            Set(expectedFiles.map { $0.resolvingSymlinksInPath() })
        )
    }
    
    func test_enumerateFiles_filter() throws {
        var expectedFiles = [tempDir.url]
        try expectedFiles.append(tempDir.createFile("file1"))
        
        _ = try tempDir.createSubdirectory("subdir")
        try expectedFiles.append(tempDir.createSubdirectory("subdir/folder1"))
        try expectedFiles.append(tempDir.createFile("subdir/file3"))
        
        _ = try tempDir.createSubdirectory("subdir/nested")
        _ = try tempDir.createFile("subdir/nested/file4")
        
        let enumerator = FileEnumerator(tempDir.url)
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
