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

@propertyWrapper
public struct Refreshable<Value> {
    private var innerValue: Value? { didSet { expiration.onUpdate(innerValue!) } }
    private let expiration: Expiration
    private let source: Source
    
    public init(wrappedValue: Value? = nil, expire: Expiration, source: Source) {
        innerValue = wrappedValue
        expiration = expire
        self.source = source
        
        if let innerValue = innerValue {
            expiration.onUpdate(innerValue)
        }
    }
    
    public var wrappedValue: Value {
        mutating get {
            if let innerValue = innerValue {
                if expiration.checkExpired(innerValue) {
                    self.innerValue = source.newValue(innerValue)
                }
            } else {
                innerValue = source.newValue(nil)
            }
            return innerValue!
        }
        set {
            innerValue = newValue
        }
    }
}

extension Refreshable {
    public init(wrappedValue: Value? = nil, expire: Expiration) where Value: ExpressibleByNilLiteral {
        self.init(wrappedValue: wrappedValue, expire: expire, source: .defaultNil())
    }
}

extension Refreshable {
    public struct Expiration {
        public var checkExpired: (Value) -> Bool
        public var onUpdate: (Value) -> Void
        
        public init(checkExpired: @escaping (Value) -> Bool, onUpdate: @escaping (Value) -> Void) {
            self.checkExpired = checkExpired
            self.onUpdate = onUpdate
        }
    }
    
    public struct Source {
        public var newValue: (_ old: Value?) -> Value
        
        public init(newValue: @escaping (Value?) -> Value) {
            self.newValue = newValue
        }
    }
}

extension Refreshable.Expiration {
    public static func ttl(_ duration: TimeInterval) -> Self {
        var expirationDate = Date()
        return .init(
            checkExpired: { _ in expirationDate < Date() },
            onUpdate: { _ in expirationDate = Date().addingTimeInterval(duration) }
        )
    }
}

extension Refreshable.Source {
    public static func defaultValue(_ defaultValue: Value) -> Self {
        .init(newValue: { _ in defaultValue })
    }
    
    public static func defaultNil() -> Self where Value: ExpressibleByNilLiteral {
        .init(newValue: { _ in nil })
    }
}
