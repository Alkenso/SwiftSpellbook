import SwiftConvenience

import XCTest


class UtilityTypesExtensionsTests: XCTestCase {
    func test_DeinitAction() {
        let exp = expectation(description: "Action on deinit.")
        DispatchQueue.global().async {
            _ = DeinitAction { exp.fulfill() }
        }
        
        waitForExpectations()
    }
}
