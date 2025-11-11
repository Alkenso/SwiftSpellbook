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

public final class ConcurrentBlockOperation: Operation, @unchecked Sendable {
    @Atomic private var state: Bool?
    private let block: @Sendable (ValueView<Bool>, @escaping @Sendable () -> Void) -> Void
    
    public init(block: @escaping @Sendable (_ isCancelled: ValueView<Bool>, _ completion: @escaping @Sendable () -> Void) -> Void) {
        self.block = block
    }
    
    public init(block: @escaping @Sendable (_ isCancelled: ValueView<Bool>) async -> Void) {
        self.block = { isCancelled, completion in
            Task.detached {
                await block(isCancelled)
                completion()
            }
        }
    }
    
    public override var isExecuting: Bool {
        state == false
    }
    
    public override var isFinished: Bool {
        state == true
    }
    
    public override var isAsynchronous: Bool { true }
    
    public override func start() {
        guard !isCancelled else {
            finish()
            return
        }
        
        willChangeValue(for: \.isExecuting)
        state = false
        didChangeValue(for: \.isExecuting)
        
        main()
    }
    
    public override func main() {
        block(.init { self.isCancelled }, finish)
    }
    
    private func finish() {
        willChangeValue(for: \.isExecuting)
        willChangeValue(for: \.isFinished)
        state = true
        didChangeValue(for: \.isExecuting)
        didChangeValue(for: \.isFinished)
    }
}
