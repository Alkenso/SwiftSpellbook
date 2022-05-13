import SwiftConvenience
import XCTest


class ObjCTests: XCTestCase {
    func test_catchNSException_success() throws {
        let result = NSException.catching {
            return 10
        }
        switch result {
        case .success(let value):
            XCTAssertEqual(value, 10)
        case .failure:
            XCTFail()
        }
    }
    
    func test_catchNSException_exception() throws {
        let result = NSException.catching {
            NSException(name: .genericException, reason: "Just", userInfo: nil).raise()
        }
        switch result {
        case .success:
            XCTFail()
        case .failure(let error):
            XCTAssertEqual(error.exception.name, .genericException)
            XCTAssertEqual(error.exception.reason, "Just")
        }
    }
}
