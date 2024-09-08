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
}
