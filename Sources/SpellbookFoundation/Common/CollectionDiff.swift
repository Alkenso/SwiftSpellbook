//
//  CollectionDiff.swift
//  SwiftSpellbook
//
//  Created by Alkenso (Vladimir Vashurkin) on 2025-02-20.
//

import Foundation

public struct CollectionDiff<Element> {
    public var added: [Element] = []
    public var updated: [Change<Element>] = []
    public var removed: [Element] = []
    public var unchanged: [Element] = []
    
    public init(
        added: [Element] = [],
        updated: [Change<Element>] = [],
        removed: [Element] = [],
        unchanged: [Element] = []
    ) {
        self.added = added
        self.updated = updated
        self.removed = removed
        self.unchanged = unchanged
    }
}

extension CollectionDiff: Equatable where Element: Equatable {}
extension CollectionDiff: Decodable where Element: Decodable {}
extension CollectionDiff: Encodable where Element: Encodable {}

extension CollectionDiff {
    public var isUnchanged: Bool { added.isEmpty && removed.isEmpty && updated.isEmpty }
}

extension CollectionDiff {
    public init<C: Collection>(
        from: C,
        to: C,
        isSimilar: (Element, Element) -> Bool,
        isEqual: (Element, Element) -> Bool
    ) where C.Element == Element {
        self.init()
        
        for toElement in to {
            if let fromElement = from.first(where: { isSimilar($0, toElement) }) {
                if let change = Change(old: fromElement, new: toElement, isEqual: isEqual) {
                    updated.append(change)
                } else {
                    unchanged.append(toElement)
                }
            } else {
                added.append(toElement)
            }
        }
        removed = from.filter { fromElement in !to.contains { isSimilar($0, fromElement) } }
    }
    
    public init<C: Collection>(from: C, to: C) where C.Element == Element, Element: Equatable {
        self.init(from: from, to: to, similarBy: \.self)
    }
    
    public init<C: Collection, Key: Equatable>(
        from: C,
        to: C,
        similarBy: KeyPath<C.Element, Key>
    ) where C.Element == Element, Element: Equatable {
        self.init(from: from, to: to, isSimilar: { $0[keyPath: similarBy] == $1[keyPath: similarBy] }, isEqual: ==)
    }
}

public struct DictionaryDiff<Key: Hashable, Value> {
    public var added: [Key: Value] = [:]
    public var updated: [Key: Change<Value>] = [:]
    public var removed: [Key: Value] = [:]
    public var unchanged: [Key: Value] = [:]
    
    public init(
        added: [Key: Value] = [:],
        updated: [Key: Change<Value>] = [:],
        removed: [Key: Value] = [:],
        unchanged: [Key: Value] = [:]
    ) {
        self.added = added
        self.updated = updated
        self.removed = removed
        self.unchanged = unchanged
    }
}

extension DictionaryDiff: Equatable where Value: Equatable {}
extension DictionaryDiff: Decodable where Key: Decodable, Value: Decodable {}
extension DictionaryDiff: Encodable where Key: Encodable, Value: Encodable {}

extension DictionaryDiff {
    public var isUnchanged: Bool { added.isEmpty && removed.isEmpty && updated.isEmpty }
}

extension DictionaryDiff {
    public init(from: [Key: Value], to: [Key: Value], isEqual: (Value, Value) -> Bool) {
        self.init()
        for (toKey, toValue) in to {
            if let fromValue = from[toKey] {
                if let change = Change(old: fromValue, new: toValue, isEqual: isEqual) {
                    updated[toKey] = change
                } else {
                    unchanged[toKey] = toValue
                }
            } else {
                added[toKey] = toValue
            }
        }
        removed = from.filter { to[$0.key] == nil }
    }
    
    public init(from: [Key: Value], to: [Key: Value]) where Value: Equatable {
        self.init(from: from, to: to, isEqual: ==)
    }
}
