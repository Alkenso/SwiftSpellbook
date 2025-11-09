@testable import SpellbookFoundation

import Foundation
import XCTest

class SynchronousExecutorTests: XCTestCase {
    func test() throws {
        let dummyValue = Dummy(value: 10, timeout: 0.05)
        
        XCTAssertEqual(synchronouslyWithContinuation(dummyValue.value), 10)
        XCTAssertEqual(try synchronouslyWithContinuation(dummyValue.resultValue).get(), 10)
        XCTAssertEqual(synchronouslyWithContinuation(dummyValue.optionalValue), 10)
        XCTAssertEqual(synchronouslyWithContinuation { dummyValue.multiReplyValue(count: 10, reply: $0) }, 10)
        XCTAssertEqual(synchronouslyWithTask { await dummyValue.asyncValue() }, 10)
        
        let dummyError = Dummy<Int>(value: nil, timeout: 0.05)
        XCTAssertThrowsError(try synchronouslyWithTask { try await dummyError.asyncError() })
    }
    
    func test_timeout() throws {
        let dummyValue = Dummy(value: 10, timeout: 0.1)
        XCTAssertNil(synchronouslyWithContinuation(timeout: 0.05, dummyValue.value))
        XCTAssertNil(synchronouslyWithContinuation(timeout: 0.05, dummyValue.resultValue))
        XCTAssertNil(synchronouslyWithContinuation(timeout: 0.05, dummyValue.optionalValue))
        XCTAssertNil(synchronouslyWithTask(timeout: 0.05) { await dummyValue.asyncValue() })
        
        let dummyError = Dummy<Int>(value: nil, timeout: 0.1)
        XCTAssertThrowsError(try synchronouslyWithTask { try await dummyError.asyncError() })
    }
}

private struct Dummy<T: Sendable>: Sendable {
    var value: T!
    var timeout: TimeInterval?
    
    func value(reply: @escaping @Sendable (T) -> Void) {
        execute { reply(value) }
    }
    
    func optionalValue(reply: @escaping @Sendable (T?) -> Void) {
        execute { reply(value) }
    }
    
    func resultValue(reply: @escaping @Sendable (Result<T, Error>) -> Void) {
        execute { reply(Result { try value.get() }) }
    }
    
    func error(reply: @escaping @Sendable (Error?) -> Void) {
        execute { reply(Result { try value.get() }.failure) }
    }
    
    func multiReplyValue(count: Int, reply: @escaping @Sendable (T) -> Void) {
        execute {
            for _ in 0..<count {
                reply(value)
            }
        }
    }
    
    private func execute(_ action: @escaping @Sendable () -> Void) {
        DispatchQueue.global().async {
            timeout.flatMap(Thread.sleep(forTimeInterval:))
            action()
        }
    }
}

extension Dummy {
    func asyncValue() async -> T {
        await withCheckedContinuation { continuation in
            value { continuation.resume(returning: $0) }
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
