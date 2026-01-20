//
//  EmptyInitializable.swift
//  SwiftSpellbook
//
//  Created by Alkenso (Vladimir Vashurkin) on 11/01/2026.
//

// MARK: - EmptyInitializable

protocol EmptyInitializable {
    init()
}

extension Array: EmptyInitializable {}
extension Dictionary: EmptyInitializable {}
extension Set: EmptyInitializable {}
extension String: EmptyInitializable {}

extension Int: EmptyInitializable {}
extension Int8: EmptyInitializable {}
extension Int16: EmptyInitializable {}
extension Int32: EmptyInitializable {}
extension Int64: EmptyInitializable {}

extension UInt: EmptyInitializable {}
extension UInt8: EmptyInitializable {}
extension UInt16: EmptyInitializable {}
extension UInt32: EmptyInitializable {}
extension UInt64: EmptyInitializable {}

extension Float: EmptyInitializable {}
extension Double: EmptyInitializable {}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Float16: EmptyInitializable {}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Int128: EmptyInitializable {}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension UInt128: EmptyInitializable {}

// MARK: - SelfIdentifiable

public protocol SelfIdentifiable: Identifiable where Self: Hashable {}

extension SelfIdentifiable where Self: Hashable {
    public var id: Self { self }
}
