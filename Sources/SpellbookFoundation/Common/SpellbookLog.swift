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
import os

public protocol SpellbookLog: Sendable {
    func _custom(
        level: SpellbookLogLevel,
        message: @autoclosure () -> Any,
        assert: Bool,
        file: StaticString,
        function: StaticString,
        line: Int,
        context: Any?
    )
}

extension SpellbookLog {
    public func verbose(
        _ message: @autoclosure () -> Any,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(level: .verbose, message: message(), assert: false, file: file, function: function, line: line, context: context)
    }
    
    public func debug(
        _ message: @autoclosure () -> Any,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(level: .debug, message: message(), assert: false, file: file, function: function, line: line, context: context)
    }
    
    public func info(
        _ message: @autoclosure () -> Any,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(level: .info, message: message(), assert: false, file: file, function: function, line: line, context: context)
    }
    
    public func warning(
        _ message: @autoclosure () -> Any,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(level: .warning, message: message(), assert: false, file: file, function: function, line: line, context: context)
    }
    
    public func error(
        _ message: @autoclosure () -> Any,
        assert: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(level: .error, message: message(), assert: assert, file: file, function: function, line: line, context: context)
    }
    
    public func fatal(
        _ message: @autoclosure () -> Any,
        assert: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(level: .fatal, message: message(), assert: assert, file: file, function: function, line: line, context: context)
    }
    
    public func custom(
        level: SpellbookLogLevel,
        message: @autoclosure () -> Any,
        assert: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        _custom(
            level: level,
            message: message(),
            assert: assert,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }
    
    @discardableResult
    public func `try`<R>(
        level: SpellbookLogLevel = .error,
        _ message: @autoclosure () -> Any,
        assert: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil,
        _ body: () throws -> R
    ) -> R? {
        do {
            return try body()
        } catch {
            custom(
                level: level,
                message: "\(message()). Error: \(error)",
                assert: assert,
                file: file,
                function: function,
                line: line,
                context: context
            )
            return nil
        }
    }
    
    @discardableResult
    public func `try`<R>(
        level: SpellbookLogLevel = .error,
        assert: Bool = false,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        context: Any? = nil,
        _ body: () throws -> R
    ) -> R? {
        do {
            return try body()
        } catch {
            custom(
                level: level,
                message: "\(error)",
                assert: assert,
                file: file,
                function: function,
                line: line,
                context: context
            )
            return nil
        }
    }
}

public enum SpellbookLogLevel: Int, Hashable, Sendable {
    /// Something generally unimportant.
    case verbose = 0
    
    /// Something which help during debugging.
    case debug = 1
    
    /// Something which you are really interested but which is not an issue or error.
    case info = 2
    
    /// Something which may cause big trouble soon.
    case warning = 3
    
    /// Something which already get in trouble.
    case error = 4
    
    /// Something which will keep you awake at night.
    case fatal = 5
}

extension SpellbookLogLevel: Comparable {
    public static func < (lhs: SpellbookLogLevel, rhs: SpellbookLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension SpellbookLogLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .verbose: "VERBOSE"
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warning: "WARNING"
        case .error: "ERROR"
        case .fatal: "FATAL"
        }
    }
}

public struct SpellbookLogRecord {
    public var source: SpellbookLogSource
    public var level: SpellbookLogLevel
    public var message: String
    public var file: StaticString
    public var function: StaticString
    public var line: Int
    public var date: Date
    public var context: Any?
    
    public init(
        source: SpellbookLogSource,
        level: SpellbookLogLevel,
        message: String,
        file: StaticString,
        function: StaticString,
        line: Int,
        date: Date,
        context: Any?
    ) {
        self.source = source
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.date = date
        self.context = context
    }
}

extension SpellbookLogRecord {
    public var fullDescription: String {
        let date = Self.dateFormatter.string(from: date)
        let file = String("\(file)").lastPathComponent.deletingPathExtension
        return "\(date) \(file).\(function):\(line) [\(source)] \(level.description.uppercased()): \(message)"
    }
    
    private static let dateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS ZZZZZ"
        return formatter
    }()
}

public struct SpellbookLogSource: Sendable {
    /// Subsystem is usually a big component or a feature of the product.
    /// For example, `SpellbookFoundation`.
    public var subsystem: String
    
    /// Category is usually some part of the subsystem.
    /// For example, `SpellbookLog` or simply `Log`.
    public var category: String
    
    /// Any arbitrary data related to the source.
    public nonisolated(unsafe) var context: Any?
    
    public init(subsystem: String, category: String, context: Any? = nil) {
        self.subsystem = subsystem
        self.category = category
        self.context = context
    }
}

extension SpellbookLogSource {
    public static func `default`(subsystem: String = "Generic", category: String = "Generic") -> Self {
        SpellbookLogSource(subsystem: subsystem, category: category)
    }
}

extension SpellbookLogSource: CustomStringConvertible {
    public var description: String { "\(subsystem)/\(category)" }
}

public struct SpellbookLogDestination: Sendable {
    public var minLevel: SpellbookLogLevel
    public var log: @Sendable (SpellbookLogRecord) -> Void
    
    public init(minLevel: SpellbookLogLevel = .info, log: @escaping @Sendable (SpellbookLogRecord) -> Void) {
        self.log = log
        self.minLevel = minLevel
    }
}

extension SpellbookLogDestination {
    public static func print(minLevel: SpellbookLogLevel = .info) -> Self {
        .init(minLevel: minLevel) { Swift.print($0.fullDescription) }
    }
    
    public static func nslog(minLevel: SpellbookLogLevel = .info) -> Self {
        .init(minLevel: minLevel) { NSLog($0.fullDescription) }
    }
}

public final class SpellbookLogger: @unchecked Sendable {
    public init(name: String, useQueue: Bool = true) {
        queue = useQueue ? DispatchQueue(label: "SpellbookLog.\(name).queue") : nil
    }
    
    /// Default logger used across `SwiftSpellbook` packages.
    /// Can be used by in the App on your own.
    public nonisolated(unsafe) static var `default` = SpellbookLogger(name: "default")
    
    public var source = SpellbookLogSource.default()
    
    public var destinations: [SpellbookLogDestination] = []
    
    /// If log messages with `assert = true` should really produce asserts.
    public var isAssertsEnabled = true
    
    public var queue: DispatchQueue?
    
    /// Create child instance, replacing log source.
    /// Children perform log facilities through their parent.
    public func withSource(_ source: SpellbookLogSource) -> SpellbookLog {
        SubsystemLogger {
            self.custom(
                source: source,
                level: $0,
                message: $1(),
                assert: $2,
                file: $3,
                function: $4,
                line: $5,
                context: $6
            )
        }
    }
    
    /// Create child instance, replacing `category` and `subsystem` if specified.
    /// Children perform logging through their parent.
    public func with(subsystem: String? = nil, category: String) -> SpellbookLog {
        var source = source
        subsystem.flatMap { source.subsystem = $0 }
        source.category = category
        
        return withSource(source)
    }
}

extension SpellbookLogger {
    /// Subsystem name used by default.
    public nonisolated(unsafe) static var internalSubsystem = "Spellbook"
    
    internal static func `internal`(category: String) -> SpellbookLog {
        `default`.with(subsystem: internalSubsystem, category: category)
    }
}

extension SpellbookLogger: SpellbookLog {
    public func _custom(
        level: SpellbookLogLevel,
        message: @autoclosure () -> Any,
        assert: Bool,
        file: StaticString,
        function: StaticString,
        line: Int,
        context: Any?
    ) {
        custom(
            source: source,
            level: level,
            message: message(),
            assert: assert,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }
    
    private func custom(
        source: SpellbookLogSource,
        level: SpellbookLogLevel,
        message: @autoclosure () -> Any,
        assert: Bool,
        file: StaticString,
        function: StaticString,
        line: Int,
        context: Any?
    ) {
        if assert && isAssertsEnabled {
            assertionFailure("\(message())", file: file, line: UInt(line))
        }
        
        let destinations = destinations.filter { level >= $0.minLevel }
        guard !destinations.isEmpty else { return }
        
        let record = SpellbookLogRecord(
            source: source, level: level, message: "\(message())",
            file: file, function: function, line: line, date: Date(), context: context
        )
        queue.async {
            destinations.forEach { $0.log(record) }
        }
    }
}

private struct SubsystemLogger: SpellbookLog {
    let logImpl: @Sendable (
        _ level: SpellbookLogLevel,
        _ message: @autoclosure () -> Any,
        _ assert: Bool,
        _ file: StaticString,
        _ function: StaticString,
        _ line: Int,
        _ context: Any?
    ) -> Void
    
    func _custom(
        level: SpellbookLogLevel,
        message: @autoclosure () -> Any,
        assert: Bool,
        file: StaticString,
        function: StaticString,
        line: Int,
        context: Any?
    ) {
        logImpl(level, message(), assert, file, function, line, context)
    }
}
