//  MIT License
//
//  Copyright (c) 2024 Alkenso (Vladimir Vashurkin)
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

public protocol _ValueUpdateWrapping: AnyObject {
    associatedtype Value
    @_spi(Private) func _readValue<R>(body: (Value) -> sending R) -> sending R
    @_spi(Private) func _updateValue<R>(body: (inout Value) -> sending R) -> sending R
}

extension _ValueUpdateWrapping {
    public func append(_ element: sending Value.Element) where Value: RangeReplaceableCollection {
        _updateValue { $0.append(element) }
    }
    
    public func append<S>(
        contentsOf newElements: sending S
    ) where Value: RangeReplaceableCollection, S: Sequence, Value.Element == S.Element {
        _updateValue { $0.append(contentsOf: newElements) }
    }
    
    public func removeAll(where shouldBeRemoved: sending (Value.Element) -> Bool) where Value: RangeReplaceableCollection {
        _updateValue { $0.removeAll(where: shouldBeRemoved) }
    }
}

extension _ValueUpdateWrapping {
    @discardableResult
    public func insert<Element: Hashable>(
        _ element: Element
    ) -> (inserted: Bool, memberAfterInsert: Element) where Value == Set<Element>, Element: Sendable {
        _updateValue { $0.insert(element) }
    }
    
    @discardableResult
    public func remove<Element: Hashable>(
        _ element: Element
    ) -> Element? where Value == Set<Element>, Element: Sendable {
        _updateValue { $0.remove(element) }
    }
    
    public func popFirst<Element: Hashable>() -> sending Element? where Value == Set<Element> {
        _updateValue { UncheckedSendable($0.popFirst()) }.wrappedValue
    }
    
    public func formUnion<Element: Hashable, S>(
        _ other: sending S
    ) where Value == Set<Element>, S: Sequence, Element == S.Element {
        _updateValue { $0.formUnion(other) }
    }
    
    public func subtract<Element: Hashable, S>(
        _ other: sending S
    ) where Value == Set<Element>, S: Sequence, Element == S.Element {
        _updateValue { $0.subtract(other) }
    }
    
    public func formIntersection<Element: Hashable, S>(
        _ other: sending S
    ) where Value == Set<Element>, S: Sequence, Element == S.Element {
        _updateValue { $0.formIntersection(other) }
    }
    
    public func formSymmetricDifference<Element: Hashable, S>(
        _ other: sending S
    ) where Value == Set<Element>, S: Sequence, Element == S.Element {
        _updateValue { $0.formSymmetricDifference(other) }
    }
}
 
extension _ValueUpdateWrapping {
    public subscript<Key: Hashable, Element>(key: Key) -> Element? where Value == [Key: Element], Key: Sendable, Element: Sendable {
        get { _readValue { $0[key] } }
        set { _updateValue { $0[key] = newValue } }
    }
    
    public func popFirst<Key: Hashable, Element>() -> sending Value.Element? where Value == [Key: Element] {
        _updateValue { UncheckedSendable($0.popFirst()) }.wrappedValue
    }
    
    @discardableResult
    public func updateValue<Key: Hashable, Element>(
        _ value: Element, forKey key: sending Key
    ) -> Element? where Value == [Key: Element], Element: Sendable {
        _updateValue { $0.updateValue(value, forKey: key) }
    }
    
    @discardableResult
    public func removeValue<Key: Hashable, Element>(forKey key: sending Key) -> sending Element? where Value == [Key: Element] {
        _updateValue { UncheckedSendable($0.removeValue(forKey: key)) }.wrappedValue
    }
}
