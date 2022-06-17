import SwiftConvenience
import SwiftConvenienceTestUtils
import XCTest

final class SCLogTests: XCTestCase {
    func test_levels() {
        let expVerbose = expectation(description: "verbose")
        let expDebug = expectation(description: "debug")
        let expInfo = expectation(description: "info")
        let expWarning = expectation(description: "warning")
        let expError = expectation(description: "error")
        let expFatal = expectation(description: "fatal")
        
        let log = SCLogger(name: "test")
        log.destinations.append { logRecord in
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
        }
        
        log.minLevel = .verbose
        
        log.verbose("verbose")
        log.debug("debug")
        log.info("info")
        log.warning("warning")
        log.error("error")
        log.fatal("fatal")
        
        waitForExpectations()
    }
    
    func test_minLevel() {
        let expectations = [
            SCLogLevel.verbose: expectation(description: "verbose"),
            SCLogLevel.debug: expectation(description: "debug"),
            SCLogLevel.info: expectation(description: "info"),
            SCLogLevel.warning: expectation(description: "warning"),
            SCLogLevel.error: expectation(description: "error"),
            SCLogLevel.fatal: expectation(description: "fatal"),
        ]
        
        let log = SCLogger(name: "test")
        log.destinations.append { logRecord in
            expectations[logRecord.level]?.fulfill()
        }
        
        expectations[.verbose]?.isInverted = true
        expectations[.debug]?.isInverted = true
        expectations[.info]?.isInverted = true
        log.minLevel = .warning
        
        log.verbose("")
        log.debug("")
        log.info("")
        log.warning("")
        log.error("")
        log.fatal("")
        
        waitForExpectations()
    }
    
    func test_subsystem() {
        enum TestSubsystem: String, SCLogSubsystem {
            case a, b
            var description: String { rawValue }
        }
        
        let log = SCLogger(name: "test")
        
        let expNoSubsystem = expectation(description: "none log subsystem")
        let expASubsystem = expectation(description: "a log subsystem")
        let expBSubsystem = expectation(description: "b log subsystem")
        
        log.destinations.append { logRecord in
            switch logRecord.subsystem as? TestSubsystem {
            case .a:
                XCTAssertEqual(logRecord.level, .warning)
                expASubsystem.fulfill()
            case .b:
                XCTAssertEqual(logRecord.level, .error)
                expBSubsystem.fulfill()
            case .none:
                XCTAssertEqual(logRecord.level, .info)
                expNoSubsystem.fulfill()
            }
        }
        
        let aSubsystemLog = log.withSubsystem(TestSubsystem.a)
        let bSubsystemLog = log.withSubsystem(TestSubsystem.b)
        
        aSubsystemLog.warning("")
        bSubsystemLog.error("")
        log.info("")
        
        waitForExpectations()
    }
}
