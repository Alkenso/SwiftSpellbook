import SpellbookFoundation

import XCTest

class CommonErrorTests: XCTestCase {
    func test_NSError() {
        let err = CommonError(.invalidArgument, userInfo: [NSDebugDescriptionErrorKey: "qwerty"])
        let nsErr = err as NSError
        
        XCTAssertEqual(nsErr.code, CommonError.Code.invalidArgument.rawValue)
        XCTAssertEqual(nsErr.userInfo[NSDebugDescriptionErrorKey] as? String, "qwerty")
    }
}
