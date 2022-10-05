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

public protocol SCLog {
    func custom(level: SCLogLevel, message: @autoclosure () -> Any, file: String, function: String, line: Int)
}

extension SCLog {
    public func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        custom(level: .verbose, message: message(), file, function, line)
    }
    
    public func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        custom(level: .debug, message: message(), file, function, line)
    }
    
    public func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        custom(level: .info, message: message(), file, function, line)
    }
    
    public func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        custom(level: .warning, message: message(), file, function, line)
    }
    
    public func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        custom(level: .error, message: message(), file, function, line)
    }
    
    public func fatal(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        custom(level: .fatal, message: message(), file, function, line)
    }
    
    public func custom(
        level: SCLogLevel, message: @autoclosure () -> Any,
        _ file: String = #file, _ function: String = #function, _ line: Int = #line
    ) {
        custom(level: level, message: message(), file: file, function: function, line: line)
    }
}

public enum SCLogLevel: Int, Hashable {
    case verbose = 0 /// something generally unimportant
    case debug = 1 /// something which help during debugging
    case info = 2 /// something which you are really interested but which is not an issue or error
    case warning = 3 /// something which may cause big trouble soon
    case error = 4 /// something which already get in trouble
    case fatal = 5 /// something which will keep you awake at night
}

extension SCLogLevel: Comparable {
    public static func < (lhs: SCLogLevel, rhs: SCLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct SCLogRecord {
    public var subsystem: SCLogSubsystem?
    public var level: SCLogLevel
    public var message: Any
    public var file: String
    public var function: String
    public var line: Int
    
    public init(subsystem: SCLogSubsystem?, level: SCLogLevel, message: Any, file: String, function: String, line: Int) {
        self.subsystem = subsystem
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }
}

public protocol SCLogSubsystem: CustomStringConvertible {}

public class SCLogger {
    private let queue: DispatchQueue
    
    public init(name: String) {
        queue = DispatchQueue(label: "SwiftConvenienceLog.\(name).queue")
    }
    
    public static let `default` = SCLogger(name: "default")
    
    public var destinations: [(SCLogRecord) -> Void] = []
    
    public var minLevel: SCLogLevel = .info
    
    public func withSubsystem(_ subsystem: SCLogSubsystem) -> SCLog {
        SCSubsystemLogger {
            self.custom(subsystem: subsystem, level: $1, message: $2(), file: $3, function: $4, line: $5)
        }
    }
}

extension SCLogger: SCLog {
    public func custom(level: SCLogLevel, message: @autoclosure () -> Any, file: String, function: String, line: Int) {
        custom(subsystem: nil, level: level, message: message(), file: file, function: function, line: line)
    }
    
    private func custom(
        subsystem: SCLogSubsystem?, level: SCLogLevel, message: @autoclosure () -> Any,
        file: String, function: String, line: Int
    ) {
        guard level >= minLevel else { return }
        
        let record = SCLogRecord(
            subsystem: subsystem, level: level, message: message(),
            file: file, function: function, line: line
        )
        queue.async {
            self.destinations.forEach { $0(record) }
        }
    }
}

private struct SCSubsystemLogger: SCLog {
    let logImpl: (_ subsystemPath: [SCLogSubsystem], _ level: SCLogLevel, _ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int) -> Void
    
    func custom(level: SCLogLevel, message: @autoclosure () -> Any, file: String, function: String, line: Int) {
        logImpl([], level, message(), file, function, line)
    }
}
