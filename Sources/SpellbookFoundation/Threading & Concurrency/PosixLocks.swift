//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// Swift-safe wrapper around `os_unfair_lock`.
/// More explanation at [OSAllocatedUnfairLock](https://developer.apple.com/documentation/os/osallocatedunfairlock)
@available(macOS, deprecated: 13.0, message: "Use `OSAllocatedUnfairLock` lock")
@available(iOS, deprecated: 16.0, message: "Use `OSAllocatedUnfairLock` lock")
@available(watchOS, deprecated: 9.0, message: "Use `OSAllocatedUnfairLock` lock")
@available(tvOS, deprecated: 16.0, message: "Use `OSAllocatedUnfairLock` lock")
public final class UnfairLock: @unchecked Sendable {
    private let raw: UnsafeMutablePointer<os_unfair_lock>
    
    public init() {
        self.raw = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        raw.initialize(to: os_unfair_lock())
    }
    
    deinit {
        raw.deallocate()
    }
    
    @available(*, noasync)
    public func lock() {
        os_unfair_lock_lock(raw)
    }
    
    @available(*, noasync)
    public func tryLock() -> Bool {
        os_unfair_lock_trylock(raw)
    }
    
    @available(*, noasync)
    public func unlock() {
        os_unfair_lock_unlock(raw)
    }
    
    public func withLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R {
        lock()
        defer { unlock() }
        return try body()
    }
}

/// Swift-safe wrapper around `pthread_rwlock_t`.
/// More explanation at [OSAllocatedUnfairLock](https://developer.apple.com/documentation/os/osallocatedunfairlock)
public final class RWLock: @unchecked Sendable {
    private let raw: UnsafeMutablePointer<pthread_rwlock_t>
    
    public init(attrs: UnsafePointer<pthread_rwlockattr_t>? = nil) {
        self.raw = UnsafeMutablePointer<pthread_rwlock_t>.allocate(capacity: 1)
        guard pthread_rwlock_init(raw, attrs) == 0 else { fatalError("Failed to pthread_rwlock_init") }
    }
    
    deinit {
        raw.deallocate()
    }
    
    @available(*, noasync)
    public func readLock() {
        pthread_rwlock_rdlock(raw)
    }
    
    @available(*, noasync)
    public func tryReadLock() -> Bool {
        pthread_rwlock_tryrdlock(raw) == 0
    }
    
    @available(*, noasync)
    public func writeLock() {
        pthread_rwlock_wrlock(raw)
    }
    
    @available(*, noasync)
    public func tryWriteLock() -> Bool {
        pthread_rwlock_trywrlock(raw) == 0
    }
    
    @available(*, noasync)
    public func unlock() {
        pthread_rwlock_unlock(raw)
    }
    
    public func withReadLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R {
        readLock()
        defer { unlock() }
        return try body()
    }
    
    public func withWriteLock<R, E: Error>(_ body: () throws(E) -> sending R) throws(E) -> sending R {
        writeLock()
        defer { unlock() }
        return try body()
    }
}
