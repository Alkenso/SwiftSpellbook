import XCTest
import sMHT_Test


class TestTemporaryDirectoryTests: XCTestCase {
    let testTempDir = TestTemporaryDirectory(prefix: "MHT-Tests")

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        try testTempDir.setUp()
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func testInitDeinit() throws {

        // check that directory is not created on disk by `init`
        let namePrefix = UUID().uuidString + "_" + tempDirPrefix
        let testTempDir = TestTemporaryDirectory(prefix: namePrefix)
        try testTempDir.setUp()
        

        // check directory is created on disk on first access
        let testTempDirUrl = testTempDir.url
        print(testTempDirUrl.path)
        print(FileManager.default.fileExists(atPath: testTempDirUrl.path))
        
        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testTempDirUrl.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)

        // check directory URL (file name should starts with `namePrefix` and ends with UUID string)
        let rootTempDirUrl = URL(fileURLWithPath: NSTemporaryDirectory())
        XCTAssertEqual(rootTempDirUrl, testTempDirUrl.deletingLastPathComponent())
        XCTAssertTrue(testTempDirUrl.lastPathComponent.starts(with: namePrefix))
        let testTempDirSuffix = testTempDirUrl.lastPathComponent.suffix(uuidStringLength)
        XCTAssertNotNil(UUID(uuidString: String(testTempDirSuffix)))

        // check directory is deleted on `deinit` even if it is not empty
        let subDirUrl = testTempDirUrl.appendingPathComponent("Subdir", isDirectory: true)
        XCTAssertNoThrow(try FileManager.default.createDirectory(at: subDirUrl, withIntermediateDirectories: false))
        let subFileUrl = testTempDirUrl.appendingPathComponent("Subfile.txt", isDirectory: false)
        XCTAssertTrue(FileManager.default.createFile(atPath: subFileUrl.path, contents: nil))
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testTempDir.url.path))
        try testTempDir.tearDown()
        XCTAssertFalse(FileManager.default.fileExists(atPath: testTempDirUrl.path))
    }

    func testCreateSubdirectory() throws {
        // simple subpath
        let testSubdirUrl = try testTempDir.createSubdirectory(subpath: "Subdir")
        XCTAssertEqual(testSubdirUrl.lastPathComponent, "Subdir")
        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testSubdirUrl.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)

        // complex subpath
        let testSubdirUrl2 = try testTempDir.createSubdirectory(subpath: "Subdir2/Subsubdir")
        XCTAssertEqual(testSubdirUrl2.lastPathComponent, "Subsubdir")
        XCTAssertEqual(testSubdirUrl2.deletingLastPathComponent().lastPathComponent, "Subdir2")
        var isDirectory2 = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testSubdirUrl2.path, isDirectory: &isDirectory2))
        XCTAssertTrue(isDirectory2.boolValue)
    }

    func testCreateFile() throws {

        // create empty file
        let testTempDir = TestTemporaryDirectory(prefix: tempDirPrefix)
        try testTempDir.setUp()
        let emptyTempFileUrl = try testTempDir.createFile(subpath: "Empty.txt")
        XCTAssertNotNil(emptyTempFileUrl)
        let emptyFileContents = try Data(contentsOf: emptyTempFileUrl)
        XCTAssertTrue(emptyFileContents.isEmpty)

        // create non-empty file
        let nonEmptyTempFileUrl = try testTempDir.createFile(subpath: "NonEmpty.txt", contents: "contents".data(using: .utf8)!)
        let nonEmptyFileContents = try Data(contentsOf: nonEmptyTempFileUrl)
        XCTAssertEqual(nonEmptyFileContents, "contents".data(using: .utf8))
    }

    func testCreateFileFailure() {

        // file exist error
        let testTempDir = TestTemporaryDirectory(prefix: tempDirPrefix)
        try testTempDir.setUp()
        XCTAssertNoThrow(try testTempDir.createFile(subpath: "Temp.txt"))
        XCTAssertThrowsError(try testTempDir.createFile(subpath: "Temp.txt"))

        // parent directory does not exists error
        XCTAssertThrowsError(try testTempDir.createFile(subpath: "Subdir/Temp.txt"))
    }

    func testContents() throws {
        func testDirContent(subpath: String = "") throws -> [URL] {
            let url = subpath.isEmpty ? testTempDir.url : testTempDir.url.appendingPathComponent(subpath)
            return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        }
        
        // base directory contents
        let testTempDir = TestTemporaryDirectory(prefix: tempDirPrefix)
        try testTempDir.setUp()
        let emptyContents = try testDirContent()
        XCTAssertTrue(emptyContents.isEmpty)
        let subdirUrl = try testTempDir.createSubdirectory(subpath: "Subdir")
        let tempFileUrl = try testTempDir.createFile(subpath: "Temp.txt")
        let nonEmptyContents = try testDirContent().map { $0.standardizedFileURL }
        XCTAssertEqual(Set<URL>(nonEmptyContents), Set<URL>([subdirUrl, tempFileUrl]))

        // subdirectory contents
        XCTAssertThrowsError(try testDirContent(subpath: "NonexistingSubdir"))
        let tempFile1 = try testTempDir.createFile(subpath: "Subdir/Temp1.txt")
        let tempFile2 = try testTempDir.createFile(subpath: "Subdir/Temp2.txt")
        let subdirContents = try testDirContent(subpath: "Subdir").map { $0.standardizedFileURL }
        XCTAssertEqual(Set<URL>(subdirContents), Set<URL>([tempFile1, tempFile2]))
    }
}
