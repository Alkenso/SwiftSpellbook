import SwiftConvenience
import SwiftConvenienceTestUtils
import XCTest

class ObjCTests: XCTestCase {
    private let objcExeption = NSException(name: .genericException, reason: "Just", userInfo: nil)
    private let swiftError = TestError("Test error")
    
    func test_catching() throws {
        XCTAssertEqual(NSException.catching { 10 }.success, 10)
        
        let failure = NSException.catching { objcExeption.raise() }.failure
        XCTAssertEqual(failure?.exception.name, objcExeption.name)
        XCTAssertEqual(failure?.exception.reason, objcExeption.reason)
    }
    
    func test_catchingAll() throws {
        XCTAssertNoThrow(try NSException.catchingAll { 10 })
        XCTAssertThrowsError(try NSException.catchingAll { objcExeption.raise() })
        XCTAssertThrowsError(try NSException.catchingAll { throw swiftError })
    }
}
