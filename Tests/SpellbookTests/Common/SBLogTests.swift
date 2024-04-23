import SpellbookFoundation
import SpellbookTestUtils
import XCTest

final class SBLogTests: XCTestCase {
    func test_levels() {
        let expVerbose = expectation(description: "verbose")
        let expDebug = expectation(description: "debug")
        let expInfo = expectation(description: "info")
        let expWarning = expectation(description: "warning")
        let expError = expectation(description: "error")
        let expFatal = expectation(description: "fatal")
        
        let log = SpellbookLogger(name: "test")
        log.destinations.append(.init(minLevel: .verbose) { logRecord in
            switch logRecord.level {
            case .verbose:
                XCTAssertEqual(logRecord.message as? String, "verbose")
                expVerbose.fulfill()
            case .debug:
                XCTAssertEqual(logRecord.message as? String, "debug")
                expDebug.fulfill()
            case .info:
                XCTAssertEqual(logRecord.message as? String, "info")
                expInfo.fulfill()
            case .warning:
                XCTAssertEqual(logRecord.message as? String, "warning")
                expWarning.fulfill()
            case .error:
                XCTAssertEqual(logRecord.message as? String, "error")
                expError.fulfill()
            case .fatal:
                XCTAssertEqual(logRecord.message as? String, "fatal")
                expFatal.fulfill()
            }
        })
        
        log.verbose("verbose")
        log.debug("debug")
        log.info("info")
        log.warning("warning")
        log.error("error")
        log.fatal("fatal")
        
        waitForExpectations()
    }
    
    func test_minLevel() {
        let expectations: [SpellbookLogLevel: XCTestExpectation] = [
            .verbose: expectation(description: "verbose"),
            .debug: expectation(description: "debug"),
            .info: expectation(description: "info"),
            .warning: expectation(description: "warning"),
            .error: expectation(description: "error"),
            .fatal: expectation(description: "fatal"),
        ]
        
        let log = SpellbookLogger(name: "test")
        log.destinations.append(.init(minLevel: .warning) { logRecord in
            expectations[logRecord.level]?.fulfill()
        })
        
        expectations[.verbose]?.isInverted = true
        expectations[.debug]?.isInverted = true
        expectations[.info]?.isInverted = true
        
        log.verbose("")
        log.debug("")
        log.info("")
        log.warning("")
        log.error("")
        log.fatal("")
        
        waitForExpectations()
    }
    
    func test_destinations() {
        let e1 = expectation(description: "warning")
        let e2 = expectation(description: "info")
        let e3 = expectation(description: "debug")
        
        let log = SpellbookLogger(name: "test")
        log.destinations.append(.init(minLevel: .warning) { _ in
            e1.fulfill()
        })
        log.destinations.append(.init(minLevel: .info) { _ in
            e2.fulfill()
        })
        log.destinations.append(.init(minLevel: .debug) { _ in
            e3.fulfill()
        })
        
        e1.expectedFulfillmentCount = 1
        e2.expectedFulfillmentCount = 2
        e3.expectedFulfillmentCount = 3
        
        log.debug("")
        log.info("")
        log.warning("")
        
        waitForExpectations()
    }
    
    func test_subsystem() {
        let log = SpellbookLogger(name: "test")
        
        let exp0 = expectation(description: "default log subsystem")
        let exp1 = expectation(description: "custom log category")
        let exp2 = expectation(description: "custom log subsystem and category")
        let exp3 = expectation(description: "custom context")
        let expUnsupported = expectation(description: "unsupported subsystem")
        expUnsupported.isInverted = true
        
        log.destinations.append(.init { logRecord in
            switch logRecord.source.subsystem {
            case SpellbookLogSource.default().subsystem:
                if logRecord.source.category != "w2" {
                    XCTAssertEqual(logRecord.source.category, "Generic")
                    exp0.fulfill()
                } else {
                    exp2.fulfill()
                }
            case "q1":
                XCTAssertEqual(logRecord.source.category, "w1")
                exp1.fulfill()
            case "q3":
                XCTAssertEqual(logRecord.source.category, "w3")
                XCTAssertEqual(logRecord.source.context as? Int, 10)
                exp3.fulfill()
            default:
                XCTFail("Unsupported subsystem")
            }
        })
        
        log.info("")
        log.with(subsystem: "q1", category: "w1").info("")
        log.with(category: "w2").info("")
        log.withSource(.init(subsystem: "q3", category: "w3", context: 10)).info("")
        
        waitForExpectations(timeout: 0.1)
    }
}
