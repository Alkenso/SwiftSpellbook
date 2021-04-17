import Foundation


// MARK: - audit_token_t

public extension audit_token_t {
    /// Returns current task audit token.
    static var current: audit_token_t? {
        withTask(mach_task_self_)
    }
    
    /// Returns task audit token.
    static func withTask(_ task: task_name_t) -> audit_token_t? {
        var token = audit_token_t()
        
        var size = mach_msg_type_number_t(MemoryLayout<audit_token_t>.size / MemoryLayout<natural_t>.size)
        let kernReturn = withUnsafeMutablePointer(to: &token) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 0) {
                task_info(task, task_flavor_t(TASK_AUDIT_TOKEN), $0, &size)
            }
        }
        
        return kernReturn == KERN_SUCCESS ? token : nil
    }
}

extension audit_token_t: Hashable {
    public static func == (lhs: audit_token_t, rhs: audit_token_t) -> Bool {
        withUnsafeBytes(of: lhs) { first -> Bool in
            withUnsafeBytes(of: rhs) { second -> Bool in
                guard first.count == second.count else { return false }
                guard let firstAddr = first.baseAddress, let secondAddr = second.baseAddress else { return false }
                return memcmp(firstAddr, secondAddr, first.count) == 0
            }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: self) { hasher.combine(bytes: $0) }
    }
}

extension audit_token_t: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        self = audit_token_t()
        self.val.0 = try container.decode(UInt32.self)
        self.val.1 = try container.decode(UInt32.self)
        self.val.2 = try container.decode(UInt32.self)
        self.val.3 = try container.decode(UInt32.self)
        self.val.4 = try container.decode(UInt32.self)
        self.val.5 = try container.decode(UInt32.self)
        self.val.6 = try container.decode(UInt32.self)
        self.val.7 = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(val.0)
        try container.encode(val.1)
        try container.encode(val.2)
        try container.encode(val.3)
        try container.encode(val.4)
        try container.encode(val.5)
        try container.encode(val.6)
        try container.encode(val.7)
    }
}
