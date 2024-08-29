import SpellbookFoundation

import XCTest

class CommonErrorTests: XCTestCase {
    func test_NSError() {
        let err = CommonError(.invalidArgument, userInfo: [NSDebugDescriptionErrorKey: "qwerty"])
        let nsErr = err as NSError
        
        XCTAssertEqual(nsErr.code, CommonError.Code.invalidArgument.rawValue)
        XCTAssertEqual(nsErr.userInfo[NSDebugDescriptionErrorKey] as? String, "qwerty")
    }
    
    func test_bridge() throws {
        let err = CommonError(.invalidArgument, userInfo: [NSDebugDescriptionErrorKey: "qwerty"])
        let encoded = try NSKeyedArchiver.archivedData(withRootObject: err, requiringSecureCoding: true)
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSError.self, from: encoded)
        let reencoded = try XCTUnwrap(decoded as? CommonError)
        
        XCTAssertEqual(reencoded.code, .invalidArgument)
        XCTAssertEqual(reencoded.userInfo[NSDebugDescriptionErrorKey] as? String, "qwerty")
    }
}
