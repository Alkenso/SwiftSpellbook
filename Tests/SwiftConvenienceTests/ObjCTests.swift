import SwiftConvenience
import SwiftConvenienceTestUtils
import XCTest

class ObjCTests: XCTestCase {
    private let objcExeption = NSException(name: .genericException, reason: "Test Obj-C ex", userInfo: nil)
    private let cppException = StdException(what: "Test c++ ex")
    private let swiftError = TestError("Test error")
    
    func test_NSException_catching() {
        XCTAssertEqual(NSException.catching { 10 }.success, 10)
        
        let failure = NSException.catching { objcExeption.raise() }.failure
        XCTAssertEqual(failure?.exception.name, objcExeption.name)
        XCTAssertEqual(failure?.exception.reason, objcExeption.reason)
    }
    
    func test_NSException_catchingAll() {
        XCTAssertNoThrow(try NSException.catchingAll { 10 })
        XCTAssertThrowsError(try NSException.catchingAll { objcExeption.raise() })
        XCTAssertThrowsError(try NSException.catchingAll { throw swiftError })
    }
    
    func test_StdException() {
        XCTAssertEqual(NSException.catching { 10 }.success, 10)
        
        let failure = StdException.catching { cppException.raise() }.failure
        XCTAssertEqual(failure?.what, cppException.what)
    }
    
    func test_catchingAny() {
        let nsEx = Result { try catchingAny { objcExeption.raise() } }.failure as? NSExceptionError
        let stdEx = Result { try catchingAny { cppException.raise() } }.failure as? StdException
        
        XCTAssertEqual(nsEx?.exception.reason, objcExeption.reason)
        XCTAssertEqual(stdEx?.what, cppException.what)
    }
}
