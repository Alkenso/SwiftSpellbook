import SwiftConvenience
import XCTest

final class EventAskTests: XCTestCase {
    func test_emptyHandlers() {
        let transformer = EventAsk<String, Int>()
        let exp = expectation(description: "Evaluated.")
        transformer.askAsync("some event") {
            XCTAssertTrue($0.isEmpty)
            exp.fulfill()
        }
        
        waitForExpectations()
    }
    
    func test_oneToMany_multipleHandlers() {
        var disposables: [Any] = []
        let postedEvent = "some event"
        let transformer = EventAsk<String, Int>()
        disposables.append(transformer.subscribe { event in
            XCTAssertEqual(event, postedEvent)
            return 1
        })
        disposables.append(transformer.subscribe { event, completion in
            XCTAssertEqual(event, postedEvent)
            completion(2)
        })
        
        let exp = expectation(description: "Evaluated.")
        transformer.askAsync(postedEvent) {
            XCTAssertTrue($0.contains(1)) // response from first handler
            XCTAssertTrue($0.contains(2)) // response from second handler
            exp.fulfill()
        }
        
        withExtendedLifetime(disposables) {
            _ = waitForExpectations()
        }
    }
}
