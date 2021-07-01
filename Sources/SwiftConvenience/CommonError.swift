import Foundation


/// Type representing error for common situations.
public struct CommonError: Error {
    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }
    
    public let code: Code
    public let userInfo: [String: Any]
}

public extension CommonError {
    enum Code: Int {
        case fatal
        case unexpected
        case unwrapNil
        case invalidArgument
    }
}

extension CommonError: CustomNSError {
    public static var errorDomain: String { "CommonErrorDomain" }
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String : Any] { userInfo }
}

public extension CommonError {
    init(_ code: Code, _ description: String? = nil) {
        var userInfo: [String: Any] = [:]
        if let description = description {
            userInfo[NSDebugDescriptionErrorKey] = description
        }
        self = .init(code, userInfo: userInfo)
    }
    
    static func fatal(_ description: String) -> Self {
        .init(.fatal, description)
    }
    
    static func unexpected(_ description: String) -> Self {
        .init(.unexpected, description)
    }
    
    static func unwrapNil(_ name: String) -> Self {
        .init(.unwrapNil, "Unexpected nil when unwrapping \(name)")
    }
    
    static func invalidArgument(arg: String, invalidValue: Any) -> Self {
        .init(.invalidArgument, "Invalid value \(invalidValue) for argument \(arg)")
    }
    
}


// MARK: Optional extension

public extension Optional where Wrapped == Error {
    /// Unwraps Error that is expected to be not nil, but syntactically is optional.
    /// Often happens when bridge ObjC <-> Swift API.
    func unwrapSafely(unexpected: Error? = nil) -> Error {
        self ?? unexpected ?? CommonError.unexpected("Unexpected nil error.")
    }
}
