import SwiftConvenience
import XCTest


final class EvaluationChainTests: XCTestCase {
    func testEmptyHandlers() {
        let chain = EvaluationChain<String, Int>()
        let exp = expectation(description: "Evaluated.")
        chain.evaluate("some event") {
            XCTAssertTrue($0.isEmpty)
            exp.fulfill()
        }
        
        waitForExpectations()
    }

    func testMultipleHandlers() {
        var disposables: [AnyObject] = []
        let postedEvent = "some event"
        let chain = EvaluationChain<String, Int>()
        disposables.append(chain.register { event in
            XCTAssertEqual(event, postedEvent)
            return 1
        })
        disposables.append(chain.register { event, completion in
            XCTAssertEqual(event, postedEvent)
            completion(2)
        })

        let exp = expectation(description: "Evaluated.")
        chain.evaluate(postedEvent) {
            XCTAssertTrue($0.contains(1)) // response from first handler
            XCTAssertTrue($0.contains(2)) // response from second handler
            exp.fulfill()
        }
        
        waitForExpectations()
    }
}
