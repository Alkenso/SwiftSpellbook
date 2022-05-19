import SwiftConvenience
import XCTest
import SwiftConvenienceTestUtils


class ObjCTests: XCTestCase {
    private let objcExeption = NSException(name: .genericException, reason: "Just", userInfo: nil)
    private let swiftError = TestError("Test error")
    
    func test_catching() throws {
        XCTAssertEqual(NSException.catching { return 10 }.success, 10)
        
        let failure = NSException.catching { objcExeption.raise() }.failure
        XCTAssertEqual(failure?.exception.name, objcExeption.name)
        XCTAssertEqual(failure?.exception.reason, objcExeption.reason)
    }
    
    func test_catchingAll() throws {
        XCTAssertNoThrow(try NSException.catchingAll { return 10 })
        XCTAssertThrowsError(try NSException.catchingAll { objcExeption.raise() })
        XCTAssertThrowsError(try NSException.catchingAll { throw swiftError })
    }
}
