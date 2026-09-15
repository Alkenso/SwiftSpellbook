//
//  AsyncFuture.swift
//  SwiftSpellbook
//
//  Created by Alkenso (Vladimir Vashurkin) on 16/01/2026.
//

import Foundation

public protocol AsyncFuture<T>: Sendable {
    associatedtype T: Sendable
    func get() async -> T
}

public final class AsyncPromise<T: Sendable>: AsyncFuture, @unchecked Sendable {
    private let lock = UnfairLock()
    private var value: T?
    private var continuations: [CheckedContinuation<T, Never>] = []
    
    public var future: any AsyncFuture<T> { self }
    
    public init() {}
    
    /// Resolves the promise once. Returns false if it was already resolved.
    @discardableResult
    public func set(_ value: T) -> Bool {
        lock.withLock {
            guard self.value == nil else { return false }
            self.value = value
            continuations.popAll().forEach { $0.resume(returning: value) }
            return true
        }
    }
    
    /// Waits for resolution and always returns the first value. Cancellation does not stop waiting.
    public func get() async -> T {
        await withCheckedContinuation { continuation in
            lock.withLock {
                if let value {
                    continuation.resume(returning: value)
                } else {
                    continuations.append(continuation)
                }
            }
        }
    }
}
