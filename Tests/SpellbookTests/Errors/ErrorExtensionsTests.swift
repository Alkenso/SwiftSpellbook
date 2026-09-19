import SpellbookFoundation
import SpellbookTestUtils

import XCTest

class ErrorExtensionsTests: XCTestCase {
    func test_secureCodingCompliant() {
        let compatibleError = NSError(domain: "test", code: 1, userInfo: [
            "compatible_key": "compatible_value",
            "compatible_key2": ["value1", "value2"],
        ])
        // No conversion.
        XCTAssertTrue(compatibleError === (compatibleError.secureCodingCompliant() as NSError))
        
        struct SwiftType {}
        let error = NSError(domain: "test", code: 1, userInfo: [
            "compatible_key": "compatible_value",
            "incompatible_key": SwiftType(),
            "maybe_incompatible_key": UUID(),
        ])
        
        XCTAssertThrowsError(try NSKeyedArchiver.archivedData(withRootObject: error, requiringSecureCoding: true))
        
        let xpcCompatible = error.secureCodingCompliant()
        XCTAssertNoThrow(try NSKeyedArchiver.archivedData(withRootObject: xpcCompatible, requiringSecureCoding: true))
    }
    
    func test_secureCodingCompliant_underlyingErrors() {
        struct SwiftType {}
        let incompatible = NSError(domain: "underlying", code: 2, userInfo: ["incompatible_key": SwiftType()])
        let error = NSError(domain: "test", code: 1, userInfo: [
            NSUnderlyingErrorKey: incompatible,
            NSMultipleUnderlyingErrorsKey: [incompatible, incompatible],
        ])
        
        XCTAssertThrowsError(try NSKeyedArchiver.archivedData(withRootObject: error, requiringSecureCoding: true))
        
        let xpcCompatible = error.secureCodingCompliant() as NSError
        XCTAssertNoThrow(try NSKeyedArchiver.archivedData(withRootObject: xpcCompatible, requiringSecureCoding: true))
        XCTAssertEqual((xpcCompatible.userInfo[NSUnderlyingErrorKey] as? NSError)?.domain, "underlying")
        XCTAssertEqual((xpcCompatible.userInfo[NSMultipleUnderlyingErrorsKey] as? [NSError])?.count, 2)
    }
}
