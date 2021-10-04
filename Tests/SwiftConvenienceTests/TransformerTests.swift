import SwiftConvenience
import XCTest


final class TransformerTests: XCTestCase {
    func test_emptyHandlers() {
        let transformer = TransformerOneToMany<String, Int>()
        let exp = expectation(description: "Evaluated.")
        transformer.async("some event") {
            XCTAssertTrue($0.isEmpty)
            exp.fulfill()
        }
        
        waitForExpectations()
    }

    func test_oneToMany_multipleHandlers() {
        var disposables: [Any] = []
        let postedEvent = "some event"
        let transformer = TransformerOneToMany<String, Int>()
        disposables.append(transformer.subscribe { event in
            XCTAssertEqual(event, postedEvent)
            return 1
        })
        disposables.append(transformer.subscribe { event, completion in
            XCTAssertEqual(event, postedEvent)
            completion(2)
        })

        let exp = expectation(description: "Evaluated.")
        transformer.async(postedEvent) {
            XCTAssertTrue($0.contains(1)) // response from first handler
            XCTAssertTrue($0.contains(2)) // response from second handler
            exp.fulfill()
        }
        
        withExtendedLifetime(disposables) {
            _ = waitForExpectations()
        }
    }
}
