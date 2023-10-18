@testable import SpellbookFoundation

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
        
        if #available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *) {
            XCTAssertEqual(try infiniteExecutor(dummyValue.asyncValue), 10)
            XCTAssertThrowsError(try infiniteExecutor(dummyError.asyncError))
        }
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
        
        if #available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *) {
            XCTAssertThrowsError(try timedExecutor(dummyValue.asyncValue))
            XCTAssertThrowsError(try timedExecutor(dummyError.asyncError))
        }
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

@available(macOS 10.15, iOS 13, tvOS 13.0, watchOS 6.0, *)
extension Dummy {
    func asyncValue() async -> T {
        await withCheckedContinuation { continuation in
            value(reply: continuation.resume(returning:))
        }
    }
    
    func asyncError() async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            error {
                if let error = $0 {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
