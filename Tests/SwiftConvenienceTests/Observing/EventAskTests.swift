import SwiftConvenience
import XCTest

final class EventAskTests: XCTestCase {
    func test_emptyHandlers() {
        let event = EventAsk<String, Int>()
        let exp = expectation(description: "Evaluated.")
        
        event.askAsync("some event") {
            XCTAssertTrue($0.isEmpty)
            exp.fulfill()
        }
        waitForExpectations()
    }
    
    func test_oneToMany_multipleHandlers() {
        var subscriptions: [SubscriptionToken] = []
        let postedEvent = "some event"
        let event = EventAsk<String, Int>()
        event.subscribe { event in
            XCTAssertEqual(event, postedEvent)
            return 1
        }
        .store(in: &subscriptions)
        event.subscribe { event, completion in
            XCTAssertEqual(event, postedEvent)
            completion(2)
        }
        .store(in: &subscriptions)
        
        let exp = expectation(description: "Evaluated.")
        event.askAsync(postedEvent) {
            XCTAssertEqual(Set($0), [1, 2])
            exp.fulfill()
        }
        waitForExpectations()
        
        let syncResult = event.askSync(postedEvent)
        XCTAssertEqual(Set(syncResult), [1, 2])
    }
    
    func test_load() {
        var subscriptions: [SubscriptionToken] = []
        let postedEvent = "some event"
        let event = EventAsk<String, Int>()
        event.subscribe { event in
            XCTAssertEqual(event, postedEvent)
            return 1
        }
        .store(in: &subscriptions)
        event.subscribe { event, completion in
            XCTAssertEqual(event, postedEvent)
            completion(2)
        }
        .store(in: &subscriptions)
        
        let count = 10_000
        let exp = expectation(description: "Evaluated.")
        exp.expectedFulfillmentCount = count
        for _ in 0..<count {
            DispatchQueue.global().async {
                event.askAsync(postedEvent) {
                    XCTAssertTrue($0.contains(1)) // response from first handler
                    XCTAssertTrue($0.contains(2)) // response from second handler
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations()
    }
    
    func test_fallack() {
        var subscriptions: [SubscriptionToken] = []
        let event = EventAsk<String, Int>()
        
        // Set event processor that takes more time than timeout.
        event.subscribe { _ in
            Thread.sleep(forTimeInterval: 0.1)
            return 1
        }.store(in: &subscriptions)
        
        // Set event processor that takes less time than timeout.
        event.subscribe { _ in
            Thread.sleep(forTimeInterval: 0.01)
            return 2
        }.store(in: &subscriptions)
        
        // Assuming
        let exp1 = expectation(description: "Evaluated.")
        event.askAsync("", timeout: .init(0.05, fallback: nil)) {
            XCTAssertEqual(Set($0), [2])
            exp1.fulfill()
        }
        waitForExpectations()
        
        let exp2 = expectation(description: "Evaluated.")
        event.askAsync("", timeout: .init(0.05, fallback: .replaceMissed(10))) {
            XCTAssertEqual(Set($0), [2, 10])
            exp2.fulfill()
        }
        waitForExpectations()
        
        let exp3 = expectation(description: "Evaluated.")
        event.askAsync("", timeout: .init(0.05, fallback: .replaceOutput([123]))) {
            XCTAssertEqual(Set($0), [123])
            exp3.fulfill()
        }
        waitForExpectations()
    }
    
    func test_extraReply() {
        var subscriptions: [SubscriptionToken] = []
        let event = EventAsk<String, Int>()
        let exp = expectation(description: "late subscribe call")
        event.subscribe {
            $1(1)
            $1(2)
            $1(3)
            exp.fulfill()
        }
        .store(in: &subscriptions)
        
        let r = event.askSync("q")
        XCTAssertEqual(r.count, 1)
        
        waitForExpectations()
    }
}
