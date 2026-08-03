//  MIT License
//
//  Copyright (c) 2026 Alkenso (Vladimir Vashurkin)
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

import Combine
import Foundation

extension ValueStore: _ValueUpdateWrapping {
    public func _readValue<R>(body: (Value) -> sending R) -> sending R {
        update { body($0) }
    }
    
    public func _updateValue<R>(body: (inout Value) -> sending R) -> sending R {
        update(body: body)
    }
}

extension ValueStore {
    @MainActor
    public final class ObservableObject: Foundation.ObservableObject {
        private var cancellables: [AnyCancellable] = []
        
        public init(store: ValueStore<Value>) {
            self.store = store
            self.value = store.value
            let token = UUID()
            store.observe { [weak self] change in
                if let change, (change.context as? UUID) != token {
                    DispatchQueue.syncOnMain { self?.value = change.new }
                }
            }
            .store(in: &cancellables)
            $value.dropFirst().sink { store.update($0, context: token) }.store(in: &cancellables)
        }
        
        @Published public var value: Value
        public let store: ValueStore<Value>
    }
    
    @MainActor
    public var observableObject: ValueStore.ObservableObject {
        .init(store: self)
    }
}

@propertyWrapper
public final class ValueStored<Value: Sendable>: Sendable {
    private let store: ValueStore<Value>
    
    public init(wrappedValue: Value) {
        self.store = .init(initialValue: wrappedValue)
    }
    
    public init(store: ValueStore<Value>) {
        self.store = store
    }
    
    public var wrappedValue: Value { store.value }
    public var projectedValue: ValueStore<Value> { store }
}
