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

import Foundation

/// Attaches arbitrary application context to macOS/iOS crash reports.
///
/// macOS/iOS crash reports contain a `__crash_info` section whose C-string fields are copied
/// verbatim into the report at crash time. Messages added here are written into that section,
/// so a crash report tells not only *where* the process died, but also *what* it was doing.
///
/// The recommended way to use it is a scoped message that lives exactly as long as the operation:
/// ```swift
/// CrashReportAugmentation.withMessage("Handling AUTH_OPEN pid=\(pid) path=\(path)") {
///     handle(message)
/// }
/// ```
///
/// - Note: All methods are thread-safe.
public enum CrashReportAugmentation: Sendable {
    /// The crash report section the message is written to.
    public enum Target: Sendable, CaseIterable {
        /// Lands in the **Application Specific Signature** block of the crash report.
        case signature

        /// Lands in the **Application Specific Backtrace** block of the crash report.
        case backtrace
    }

    /// Opaque handle of an attached message, used to remove it later.
    ///
    /// - Note: Returned by ``addMessage(target:header:_:)`` and consumed by ``removeMessage(_:)``.
    public struct MessageID: Sendable {
        internal var target: Target
        internal var id: Int
    }
    
    private static let lock = NSLock()
    private nonisolated(unsafe) static let storageSignature = Storage()
    private nonisolated(unsafe) static let storageBacktrace = Storage()
    private nonisolated(unsafe) static var currentMessageID = 0
    
    /// Master switch. When `false`, any calls to methods does nothing. Defaults to `true`.
    ///
    /// - Note: Disabling does not clear already attached messages. Call ``removeAll(_:)``
    ///     before disabling if the crash report should not contain them.
    public nonisolated(unsafe) static var isEnabled = true

    /// Target used when the message is added without an explicit one. Defaults to ``Target/signature``.
    public nonisolated(unsafe) static var defaultTarget: Target = .signature

    /// Whether each message is extended with the execution context it was added from. Defaults to `true`.
    ///
    /// Appends whichever of task name, dispatch queue label, thread name and pthread id
    /// are available, for example `task=es_task|queue=com.app.es.worker|pthread=123456`.
    /// It is what makes a crash on an anonymous worker thread readable.
    public nonisolated(unsafe) static var includeThreadInfo = true

    /// Whether adding or removing a message immediately writes the crash info section. Defaults to `true`.
    ///
    /// - Note: Setting it to `false` avoids the write on every call in hot paths,
    ///     but then ``updateCrashInfo()`` must be called manually for the section
    ///     to reflect the attached messages.
    public nonisolated(unsafe) static var updateCrashInfoAutomatically = true

    /// The crash info structure the messages are written into. Defaults to `CrashInfo.shared`.
    ///
    /// - Note: Intended to be overridden in tests. In production the default value
    ///     points to the `__crash_info` section the crash reporter actually reads.
    public nonisolated(unsafe) static var crashInfo = CrashInfo.shared
    
    /// Attaches a message to the crash report until it is explicitly removed.
    ///
    /// The message is numbered and, if ``includeThreadInfo`` is set, tagged with the execution
    /// context it was added from.
    ///
    /// - Parameters:
    ///   - target: Section of the crash report to attach the message to. Defaults to ``defaultTarget``.
    ///   - header: Reserved. Currently has no effect on the resulting message.
    ///   - message: The context to put into the crash report.
    /// - Returns: Handle to pass to ``removeMessage(_:)``. If ``isEnabled`` is `false`,
    ///     no message is attached and the returned handle refers to nothing.
    /// - Note: Prefer `withMessage` when the message lifetime matches a scope:
    ///     it cannot leak the message on an early return or a throw.
    public static func addMessage(
        target: Target? = nil,
        header: String? = nil,
        _ message: String
    ) -> MessageID {
        guard isEnabled else { return MessageID(target: .signature, id: -1) }
        
        let target = target ?? defaultTarget
        let storage = storage(for: target)
        let threadInfo = includeThreadInfo ? threadInfo() : ""
        return lock.withLock {
            currentMessageID += 1
            storage.add("#\(currentMessageID) \(threadInfo)\n\(message)", for: currentMessageID)
            if updateCrashInfoAutomatically {
                storage.updateCrashInfo(for: target)
            }
            return MessageID(target: target, id: currentMessageID)
        }
    }
    
    /// Detaches the message previously attached by ``addMessage(target:header:_:)``.
    ///
    /// - Parameter id: Handle returned by ``addMessage(target:header:_:)``.
    ///     Removing an already removed message is a no-op.
    public static func removeMessage(_ id: MessageID) {
        guard isEnabled else { return }
        
        let storage = storage(for: id.target)
        lock.withLock {
            storage.remove(id.id)
            if updateCrashInfoAutomatically {
                storage.updateCrashInfo(for: id.target)
            }
        }
    }
    
    /// Detaches all messages attached to the given target.
    ///
    /// - Parameter target: Section of the crash report to clear.
    ///     Messages attached to the other target are left intact.
    public static func removeAll(_ target: Target) {
        guard isEnabled else { return }
        let storage = storage(for: target)
        lock.withLock {
            storage.removeAll()
            if updateCrashInfoAutomatically {
                storage.updateCrashInfo(for: target)
            }
        }
    }
    
    /// Attaches the message for the duration of `body` and detaches it afterwards.
    ///
    /// The message is removed on any exit from `body`, including a thrown error.
    /// ```swift
    /// CrashReportAugmentation.withMessage("Processing job \(job.id)") {
    ///     process(job)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - message: The context to put into the crash report.
    ///   - target: Section of the crash report to attach the message to. Defaults to ``defaultTarget``.
    ///   - body: The operation to perform with the message attached.
    /// - Returns: The value returned by `body`.
    /// - Throws: Whatever `body` throws.
    public static func withMessage<R, E: Error>(
        _ message: String,
        target: Target? = nil,
        body: () throws(E) -> R
    ) throws(E) -> R {
        let id = addMessage(target: target, message)
        defer { removeMessage(id) }
        return try body()
    }
    
    /// Attaches the message for the duration of the asynchronous `body` and detaches it afterwards.
    ///
    /// The message is removed on any exit from `body`, including a thrown error.
    /// ```swift
    /// await CrashReportAugmentation.withMessage("Processing job \(job.id)") {
    ///     await process(job)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - message: The context to put into the crash report.
    ///   - target: Section of the crash report to attach the message to. Defaults to ``defaultTarget``.
    ///   - body: The operation to perform with the message attached.
    /// - Returns: The value returned by `body`.
    /// - Throws: Whatever `body` throws.
    /// - Note: The message stays attached across suspension points, so it is visible
    ///     in the crash report regardless of the thread `body` resumes on.
    public static func withMessage<R, E: Error>(
        _ message: String,
        target: Target? = nil,
        body: () async throws(E) -> R
    ) async throws(E) -> R {
        let id = addMessage(target: target, message)
        defer { removeMessage(id) }
        return try await body()
    }
    
    /// Writes all currently attached messages into ``crashInfo``, for both targets.
    ///
    /// - Note: Needed only when ``updateCrashInfoAutomatically`` is `false`. Otherwise
    ///     the crash info is already up to date after every add or remove.
    public static func updateCrashInfo() {
        lock.withLock {
            storageSignature.updateCrashInfo(for: .signature)
            storageBacktrace.updateCrashInfo(for: .backtrace)
        }
    }
    
#if swift(>=6.3)
    @inline(always)
#else
    @inline(__always)
#endif
    private static func storage(for target: Target) -> Storage {
        switch target {
        case .signature: storageSignature
        case .backtrace: storageBacktrace
        }
    }
    
    private static func threadInfo() -> String {
        var tid: UInt64 = 0
        pthread_threadid_np(nil, &tid)
        
        var taskName: String?
#if compiler(>=6.2)
        if #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *) {
            taskName = Task.name
        }
#endif
        
        return [
            ("task", taskName ?? ""),
            ("queue", String(cString: __dispatch_queue_get_label(nil))),
            ("thread", Thread.current.name ?? ""),
            ("pthread", String(tid)),
        ].filter { !$0.1.isEmpty }.map { "\($0.0)=\($0.1)" }.joined(separator: "|")
    }
}

private final class Storage {
    private var messages: [Int: String] = [:]
    
    func updatePointer(_ target: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) {
        let string = messages
            .sorted { $0.key < $1.key }
            .map(\.value)
            .joined(separator: "\n\n")
        
        let oldPointer = target.pointee
        target.pointee = !string.isEmpty ? string.withCString(strdup) : nil
        oldPointer?.deallocate()
    }
    
    func add(_ message: String, for id: Int) {
        messages[id] = message
    }
    
    func remove(_ id: Int) {
        messages.removeValue(forKey: id)
    }
    
    func removeAll() {
        messages.removeAll()
    }
    
    func updateCrashInfo(for target: CrashReportAugmentation.Target) {
        let crashInfo = CrashReportAugmentation.crashInfo
        switch target {
        case .signature: updatePointer(&crashInfo.pointee.signature)
        case .backtrace: updatePointer(&crashInfo.pointee.backtrace)
        }
    }
}
