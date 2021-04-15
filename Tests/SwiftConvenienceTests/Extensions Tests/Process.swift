#if os(macOS)
import SwiftConvenience
import SwiftConvenienceTestUtils

import XCTest


class ProcessExtensionsTests: XCTestCase {
    func test_launchTool_success() throws {
        let (exitCode, stdout, stderr) = Process.launch(
            tool: URL(fileURLWithPath: "/usr/bin/id"),
            arguments: ["-u"]
        )
        XCTAssertEqual(exitCode, 0)
        XCTAssertFalse(stdout.isEmpty)
        XCTAssertTrue(stderr.isEmpty)
    }
    
    func test_launchTool_error() throws {
        let (exitCode, stdout, stderr) = Process.launch(
            tool: URL(fileURLWithPath: "/usr/bin/id"),
            arguments: ["-u", UUID().uuidString]
        )
        XCTAssertGreaterThan(exitCode, 0)
        XCTAssertTrue(stdout.isEmpty)
        XCTAssertFalse(stderr.isEmpty)
    }
}

#endif
