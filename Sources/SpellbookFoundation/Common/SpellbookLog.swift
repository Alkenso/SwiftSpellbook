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

public protocol SpellbookLog {
    func custom(level: SpellbookLogLevel, message: @autoclosure () -> Any, assert: Bool, file: StaticString, function: StaticString, line: Int)
}

extension SpellbookLog {
    public func verbose(_ message: @autoclosure () -> Any, _ file: StaticString = #file, _ function: StaticString = #function, line: Int = #line) {
        custom(level: .verbose, message: message(), assert: false, file, function, line)
    }
    
    public func debug(_ message: @autoclosure () -> Any, _ file: StaticString = #file, _ function: StaticString = #function, line: Int = #line) {
        custom(level: .debug, message: message(), assert: false, file, function, line)
    }
    
    public func info(_ message: @autoclosure () -> Any, _ file: StaticString = #file, _ function: StaticString = #function, line: Int = #line) {
        custom(level: .info, message: message(), assert: false, file, function, line)
    }
    
    public func warning(_ message: @autoclosure () -> Any, _ file: StaticString = #file, _ function: StaticString = #function, line: Int = #line) {
        custom(level: .warning, message: message(), assert: false, file, function, line)
    }
    
    public func error(_ message: @autoclosure () -> Any, assert: Bool = false, _ file: StaticString = #file, _ function: StaticString = #function, line: Int = #line) {
        custom(level: .error, message: message(), assert: assert, file, function, line)
    }
    
    public func fatal(_ message: @autoclosure () -> Any, assert: Bool = false, _ file: StaticString = #file, _ function: StaticString = #function, line: Int = #line) {
        custom(level: .fatal, message: message(), assert: assert, file, function, line)
    }
    
    public func custom(
        level: SpellbookLogLevel, message: @autoclosure () -> Any, assert: Bool,
        _ file: StaticString = #file, _ function: StaticString = #function, _ line: Int = #line
    ) {
        custom(level: level, message: message(), assert: assert, file: file, function: function, line: line)
    }
}

public enum SpellbookLogLevel: Int, Hashable {
    case verbose = 0 /// something generally unimportant.
    case debug = 1 /// something which help during debugging.
    case info = 2 /// something which you are really interested but which is not an issue or error.
    case warning = 3 /// something which may cause big trouble soon.
    case error = 4 /// something which already get in trouble.
    case fatal = 5 /// something which will keep you awake at night.
}

extension SpellbookLogLevel: Comparable {
    public static func < (lhs: SpellbookLogLevel, rhs: SpellbookLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct SpellbookLogRecord {
    public var source: SpellbookLogSource
    public var level: SpellbookLogLevel
    public var message: Any
    public var file: StaticString
    public var function: StaticString
    public var line: Int
    
    public init(source: SpellbookLogSource, level: SpellbookLogLevel, message: Any, file: StaticString, function: StaticString, line: Int) {
        self.source = source
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }
}

public struct SpellbookLogSource {
    public var subsystem: String
    public var category: String
    public var context: Any?
    
    public init(subsystem: String, category: String, context: Any? = nil) {
        self.subsystem = subsystem
        self.category = category
        self.context = context
    }
}

extension SpellbookLogSource {
    public static func `default`(category: String = "Generic") -> Self {
        SpellbookLogSource(
            subsystem: Bundle.main.bundleIdentifier ?? "Generic",
            category: category
        )
    }
}

extension SpellbookLogSource: CustomStringConvertible {
    public var description: String { "\(subsystem)/\(category)" }
}

public final class SpellbookLogger {
    private let queue: DispatchQueue?
    
    public init(name: String, useQueue: Bool = true) {
        queue = useQueue ? DispatchQueue(label: "SpellbookLog.\(name).queue") : nil
    }
    
    public static var `default` = SpellbookLogger(name: "default")
    
    public var source = SpellbookLogSource.default()
    
    public var destinations: [(SpellbookLogRecord) -> Void] = []
    
    public var minLevel: SpellbookLogLevel = .info
    
    /// If log messages with `assert = true` should really produce asserts.
    public var isAssertsEnabled = true
    
    /// Create child instance, replacing log source.
    /// Children perform log facilities through their parent.
    public func withSource(_ source: SpellbookLogSource) -> SpellbookLog {
        SubsystemLogger {
            self.custom(source: source, level: $0, message: $1(), assert: $2, file: $3, function: $4, line: $5)
        }
    }
    
    /// Create child instance, replacing log subsystem.
    /// Children perform log facilities through their parent.
    public func with(subsystem: String? = nil, category: String) -> SpellbookLog {
        var source = source
        subsystem.flatMap { source.subsystem = $0 }
        source.category = category
        
        return withSource(source)
    }
}

extension SpellbookLogger {
    /// Subsystem name used by default.
    public static var internalSubsystem = "Spellbook"
    
    internal static func `internal`(category: String) -> SpellbookLog {
        `default`.with(subsystem: internalSubsystem, category: category)
    }
}

extension SpellbookLogger: SpellbookLog {
    public func custom(level: SpellbookLogLevel, message: @autoclosure () -> Any, assert: Bool, file: StaticString, function: StaticString, line: Int) {
        custom(source: source, level: level, message: message(), assert: assert, file: file, function: function, line: line)
    }
    
    private func custom(
        source: SpellbookLogSource, level: SpellbookLogLevel, message: @autoclosure () -> Any, assert: Bool,
        file: StaticString, function: StaticString, line: Int
    ) {
        guard level >= minLevel else { return }
        
        if assert && isAssertsEnabled {
            assertionFailure("\(message())", file: file, line: UInt(line))
        }
        
        let record = SpellbookLogRecord(
            source: source, level: level, message: message(),
            file: file, function: function, line: line
        )
        if let queue {
            queue.async {
                self.destinations.forEach { $0(record) }
            }
        } else {
            self.destinations.forEach { $0(record) }
        }
    }
}

private struct SubsystemLogger: SpellbookLog {
    let logImpl: (_ level: SpellbookLogLevel, _ message: @autoclosure () -> Any, _ assert: Bool, _ file: StaticString, _ function: StaticString, _ line: Int) -> Void
    
    func custom(level: SpellbookLogLevel, message: @autoclosure () -> Any, assert: Bool, file: StaticString, function: StaticString, line: Int) {
        logImpl(level, message(), assert, file, function, line)
    }
}
