import SwiftConvenience
import XCTest


class CancellationTokenTests: XCTestCase {
    func test_basic() {
        var isCancelled = false
        let expCancel = expectation(description: "")
        let token = CancellationToken {
            isCancelled = true
            expCancel.fulfill()
        }
        
        XCTAssertFalse(isCancelled)
        
        token.cancel()
        
        waitForExpectations()
        XCTAssertTrue(isCancelled)
    }
    
    func test_cancelOnce() {
        let expCancel = expectation(description: "")
        let token = CancellationToken { expCancel.fulfill() }
        
        token.cancel()
        token.cancel()
        token.cancel()
        
        waitForExpectations()
    }
    
    func test_children() {
        let token = CancellationToken()
        
        var isCancelled = false
        let expCancel = expectation(description: "")
        expCancel.expectedFulfillmentCount = 2
        
        token.addChild {
            isCancelled = true
            expCancel.fulfill()
        }
        
        let childToken = CancellationToken { expCancel.fulfill() }
        token.addChild(childToken)
        
        XCTAssertFalse(isCancelled)
        XCTAssertFalse(childToken.isCancelled)
        
        token.cancel()
        waitForExpectations()
        
        XCTAssertTrue(isCancelled)
        XCTAssertTrue(token.isCancelled)
        XCTAssertTrue(childToken.isCancelled)
    }
    
    func test_childrenWhenCancelled() {
        let token = CancellationToken()
        token.cancel()
        
        let expCancel = expectation(description: "")
        token.addChild {
            expCancel.fulfill()
        }
        waitForExpectations()
    }
}
