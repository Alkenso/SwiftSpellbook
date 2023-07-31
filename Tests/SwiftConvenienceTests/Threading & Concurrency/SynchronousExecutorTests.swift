@testable import SwiftConvenience

import Foundation
import XCTest

class SynchronousExecutorTests: XCTestCase {
    func test() throws {
        let infiniteExecutor = SynchronousExecutor(timeout: nil)
        let dummyValue = Dummy(value: 10, timeout: 0.05)
        XCTAssertEqual(try infiniteExecutor(dummyValue.value), 10)
        XCTAssertEqual(try infiniteExecutor(dummyValue.resultValue), 10)
        XCTAssertEqual(try infiniteExecutor(dummyValue.optionalValue), 10)
        XCTAssertEqual(try infiniteExecutor { dummyValue.multiReplyValue(count: 10, reply: $0) }, 10)
        
        let dummyError = Dummy<Int>(value: nil, timeout: 0.05)
        XCTAssertThrowsError(try infiniteExecutor(dummyError.error))
        XCTAssertThrowsError(try infiniteExecutor(dummyError.resultValue))
        XCTAssertEqual(try infiniteExecutor(dummyError.optionalValue), nil)
    }
    
    func test_timeout() throws {
        let timedExecutor = SynchronousExecutor(timeout: 0.05)
        let dummyValue = Dummy(value: 10, timeout: 0.1)
        XCTAssertThrowsError(try timedExecutor(dummyValue.value))
        XCTAssertThrowsError(try timedExecutor(dummyValue.resultValue))
        XCTAssertThrowsError(try timedExecutor(dummyValue.optionalValue))
        
        let dummyError = Dummy<Int>(value: nil, timeout: 0.1)
        XCTAssertThrowsError(try timedExecutor(dummyError.error))
        XCTAssertThrowsError(try timedExecutor(dummyError.resultValue))
        XCTAssertThrowsError(try timedExecutor(dummyError.optionalValue))
    }
}

private struct Dummy<T> {
    var value: T!
    var timeout: TimeInterval?
    
    func value(reply: @escaping (T) -> Void) {
        execute { reply(value) }
    }
    
    func optionalValue(reply: @escaping (T?) -> Void) {
        execute { reply(value) }
    }
    
    func resultValue(reply: @escaping (Result<T, Error>) -> Void) {
        execute { reply(Result { try value.get() }) }
    }
    
    func error(reply: @escaping (Error?) -> Void) {
        execute { reply(Result { try value.get() }.failure) }
    }
    
    func multiReplyValue(count: Int, reply: @escaping (T) -> Void) {
        execute {
            for _ in 0..<count {
                reply(value)
            }
        }
    }
    
    private func execute(_ action: @escaping () -> Void) {
        DispatchQueue.global().async {
            timeout.flatMap(Thread.sleep(forTimeInterval:))
            action()
        }
    }
}
