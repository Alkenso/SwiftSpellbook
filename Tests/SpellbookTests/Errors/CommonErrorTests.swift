import SpellbookFoundation

import XCTest

class CommonErrorTests: XCTestCase {
    func test_printingUsesConsistentReadableDescription() {
        let error: Error = CommonError(.invalidArgument, userInfo: [
            NSDebugDescriptionErrorKey: "Invalid count",
            "zebra": 2,
            "context": "first line\nsecond line",
        ])
        let expected = #"Error Domain=CommonErrorDomain Code=InvalidArgument(4) "Invalid count" UserInfo={context="first line\nsecond line", zebra=2}"#
        var printed = ""
        print(error, terminator: "", to: &printed)
        var debugPrinted = ""
        debugPrint(error, terminator: "", to: &debugPrinted)
        
        XCTAssertEqual(printed, expected)
        XCTAssertEqual(debugPrinted, expected)
        XCTAssertEqual(String(reflecting: error), expected)
        XCTAssertEqual("\(error)", expected)
    }
    
    func test_printingUnderlyingErrorAndMessageFallback() {
        let error = CommonError("Request failed", reason: CommonError.timedOut(what: "Connection"))
        
        XCTAssertEqual(error.description,
                       #"Error Domain=CommonErrorDomain Code=General(0) "Request failed" UserInfo={NSUnderlyingError=Error Domain=CommonErrorDomain Code=TimedOut(8) "Connection timed out"}"#)
        XCTAssertEqual(CommonError(.general).description, "Error Domain=CommonErrorDomain Code=General(0)")
        XCTAssertEqual(CommonError(localized: "Try again").description, #"Error Domain=CommonErrorDomain Code=General(0) "Try again""#)
    }
    
    func test_loggerUsesPrettyDescription() {
        let logged = expectation(description: "Logged error")
        let logger = SpellbookLogger(name: "CommonErrorTests", useQueue: false)
        logger.destinations = [.init { record in
            XCTAssertEqual(record.message, #"Error Domain=CommonErrorDomain Code=General(0) "Request failed" UserInfo={attempt=2}"#)
            logged.fulfill()
        }]
        
        let error: Error = CommonError("Request failed").updatingUserInfo(2, for: "attempt")
        logger.error(error)
        wait(for: [logged], timeout: 1)
    }
    
    func test_factoryDescriptions() {
        XCTAssertEqual(CommonError.unwrapNil("result").userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Unexpected nil when unwrapping 'result'")
        XCTAssertEqual(CommonError.invalidArgument(arg: "count", invalidValue: nil).userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Invalid value nil for argument 'count'")
        XCTAssertEqual(CommonError.cast(name: "value", 1, to: String.self).userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Failed to cast 'value' from type Int to String")
        XCTAssertEqual(CommonError.notFound(what: "Item", value: 42, where: "cache").userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Item '42' not found in cache")
        XCTAssertEqual(CommonError.outOfRange(what: "Index", value: 5, where: "items", limitValue: 3).userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Index '5' is out of range in items (limit: '3')")
    }
    
    func test_factoryDescriptionsIgnoreBlankDetails() {
        XCTAssertEqual(CommonError.timedOut(what: "Request", description: " \n ").userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Request timed out")
        XCTAssertEqual(CommonError.timedOut(what: "Request", description: "  Try again.\n").userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Request timed out. Try again.")
        XCTAssertEqual(CommonError.cast(name: " ", 1, to: String.self).userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Failed to cast from type Int to String")
        XCTAssertEqual(CommonError.notFound(what: "Item", where: " \n").userInfo[NSDebugDescriptionErrorKey] as? String,
                       "Item not found")
    }
    
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
