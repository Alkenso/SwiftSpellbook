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

extension Dictionary {
    /// Get and set value in nested dictionary
    /// 'Set' notes:
    ///     1. if key path refers to nonexistent nested dictionary, it will be created as [AhyHashable: Any]
    ///     2. if key path refers to type that cannot be casted to [AnyHashable: Any], 'set' will do nothing
    ///     3. 'insert(value:at:)' is failable replacement of 'set'
    public subscript(keyPath keyPath: [AnyHashable]) -> Any? {
        get {
            guard let lastKey = keyPath.last else { return nil }
            
            var lastDict: [AnyHashable: Any] = self
            for keyPathComponent in keyPath.dropLast() {
                guard let nestedDict = lastDict[keyPathComponent] as? [AnyHashable: Any] else {
                    return nil
                }
                lastDict = nestedDict
            }
            
            return lastDict[lastKey]
        }
        set {
            try? insert(value: newValue, at: keyPath)
        }
    }
    
    /// Inserts value into nested dictionary at key path
    /// If nested dictionary(one or multiple) does not exist, they are created
    /// If value at any nested level according to key path has unappropriate type, the error is thrown
    public mutating func insert(value: Any?, at keyPath: [AnyHashable]) throws {
        guard let nextKey = keyPath.first as? Key else { return }
        
        let nestedKeyPath = Array(keyPath.dropFirst())
        guard !nestedKeyPath.isEmpty else {
            let typedValue = try (value as? Value)
                .get(ifNil: CommonError.cast(
                    value,
                    to: Value.self,
                    description: "Failed to insert value of unappropriate type"
                ))
            self[nextKey] = typedValue
            return
        }
        
        var nested = try nestedDict(for: nextKey)
        try nested.insert(value: value, at: nestedKeyPath)
        self[nextKey] = try (nested as? Value)
            .get(ifNil: CommonError.cast(
                value,
                to: Value.self,
                description: "Failed to insert value of unappropriate type as nested dictionary"
            ))
    }
    
    private func nestedDict(for key: Key) throws -> [AnyHashable: Any] {
        guard let value = self[key] else { return [AnyHashable: Any]() }
        let nestedDict = try (value as? [AnyHashable: Any])
            .get(ifNil: CommonError.cast(
                value,
                to: [AnyHashable: Any].self,
                description: "Trying to insert value to nested dictionary but unexpected type found"
            ))
        return nestedDict
    }
}

extension Dictionary {
    /// Get and set value in nested dictionary using dot-separated key path
    public subscript(dotPath dotPath: String) -> Any? {
        get { self[keyPath: dotPath.components(separatedBy: ".")] }
        set { try? insert(value: newValue, at: dotPath) }
    }

    /// Inserts value in nested dictionary using dot-separated key path
    public mutating func insert(value: Any?, at dotPath: String) throws {
        try insert(value: value, at: dotPath.components(separatedBy: "."))
    }
}
