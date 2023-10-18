#if os(macOS)

import SpellbookFoundation

import XCTest

class SysctlTests: XCTestCase {
    func test() throws {
        let (path, args) = try Sysctl.procArgs(for: getpid())
        XCTAssertEqual(path.lastPathComponent, "xctest")
        XCTAssertFalse(args.isEmpty)
    }
}

#endif
