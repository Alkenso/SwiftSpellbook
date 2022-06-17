import SwiftConvenience
import SwiftConvenienceTestUtils

import XCTest

class FileEnumeratorTests: XCTestCase {
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
    
    func test_enumerateFiles() throws {
        var expectedFiles = [tempDir.url]
        try expectedFiles.append(tempDir.createFile("file1"))
        try expectedFiles.append(tempDir.createFile("file2"))
        try expectedFiles.append(tempDir.createSubdirectory("subdir"))
        try expectedFiles.append(tempDir.createFile("subdir/file3"))
        try expectedFiles.append(tempDir.createSubdirectory("subdir/nested"))
        try expectedFiles.append(tempDir.createFile("subdir/nested/file4"))
        
        let enumeratedFiles = FileEnumerator(tempDir.url)
            .reduce(into: [URL]()) { $0.append($1) }
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
        
        let enumeratedFiles = FileEnumerator(types: [.regular], tempDir.url)
            .reduce(into: [URL]()) { $0.append($1) }
        XCTAssertEqual(
            Set(enumeratedFiles.map { $0.resolvingSymlinksInPath() }),
            Set(expectedFiles.map { $0.resolvingSymlinksInPath() })
        )
    }
    
    func test_enumerateFiles_filter() throws {
        var expectedFiles = [tempDir.url]
        _ = try tempDir.createFile("file1")
        try expectedFiles.append(tempDir.createSubdirectory("subdir"))
        _ = try tempDir.createFile("subdir/file3")
        try expectedFiles.append(tempDir.createSubdirectory("subdir/nested"))
        _ = try tempDir.createFile("subdir/nested/file4")
        
        let enumerator = FileEnumerator(tempDir.url)
        enumerator.filters.append(.types([.directory]))
        let enumeratedFiles = enumerator.reduce(into: [URL]()) { $0.append($1) }
        XCTAssertEqual(
            Set(enumeratedFiles.map { $0.resolvingSymlinksInPath() }),
            Set(expectedFiles.map { $0.resolvingSymlinksInPath() })
        )
    }
}
