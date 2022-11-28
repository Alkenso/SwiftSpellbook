//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
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

/// Queue that blocks thread execution waiting new elements.
/// All methods are designed to be thread-safe.
public class BlockingQueue<Element> {
    private var condition = pthread_cond_t()
    private var mutex = pthread_mutex_t()
    private var elements: [(Element, Bool)] = []
    private var invalidated = false
    
    public init() {
        guard pthread_cond_init(&self.condition, nil) == 0 else { fatalError("Failed to pthread_cond_init") }
        guard pthread_mutex_init(&self.mutex, nil) == 0 else { fatalError("Failed to pthread_mutex_init") }
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
        pthread_cond_destroy(&condition)
    }
    
    /// Enqueues the element.
    /// - Note: Do NOT enqueue elements into invalidated queue.
    public func enqueue(_ element: Element) {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        
        guard !invalidated else {
            assertionFailure("Failed to enqueue the element into invalidated queue. The element is dropped")
            return
        }
        
        elements.append((element, false))
        pthread_cond_signal(&condition)
    }
    
    /// Dequeues next element from the queue.
    /// - Returns: Next element or `nil` if queue has been invalidated.
    public func dequeue() -> Element? {
        var dummy = false
        return dequeue(isCancelled: &dummy)
    }
    
    /// Dequeues next element from the queue.
    /// - Parameter isCancelled: Boolean indicating the element processing was cancelled or not.
    /// - Returns: Next element or `nil` if queue has been invalidated.
    public func dequeue(isCancelled: inout Bool) -> Element? {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        
        while true {
            if elements.isEmpty {
                guard !invalidated else { return nil }
                pthread_cond_wait(&condition, &mutex)
            } else {
                let next = elements.removeFirst()
                isCancelled = next.1
                return next.0
            }
        }
    }
    
    /// Marks all elements in the queue as `cancelled`.
    public func cancel() {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        
        elements.mutateElements { $0.1 = true }
    }
    
    /// Invalidates the queue.
    /// After this call, all elements are removed from the queue and `dequeue` methods return `nil`.
    public func invalidate(removeAll: Bool = true) {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        
        invalidated = true
        if removeAll {
            elements.removeAll()
        }
        pthread_cond_broadcast(&condition)
    }
}

extension BlockingQueue {
    /// Current number of the elements in the queue.
    /// Designed to be used only for debug purposes: the count may be changed from different threads,
    /// so there is no guarantee that the value remains reliable after the method is executed.
    public var approximateCount: Int {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        
        return elements.count
    }
}
