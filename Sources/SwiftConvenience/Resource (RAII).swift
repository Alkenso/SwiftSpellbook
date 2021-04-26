import Foundation


/// Resource wrapper that follows the rule 'Resource acquisition is initialization'.
/// It is a resource wrapper that performs cleanup when resource is not used anymore.
public class Resource<T> {
    public var value: T
    
    private init(_ value: T, cleanup: @escaping (T) -> Void) {
        self.value = value
        _cleanup = cleanup
    }
    
    deinit {
        _cleanup(value)
    }
    
    private let _cleanup: (T) -> Void
}

public extension Resource {
    static func raii(_ value: T, cleanup: @escaping (T) -> Void) -> Resource {
        Resource(value, cleanup: cleanup)
    }
    
    static func stub(_ value: T) -> Resource {
        Resource(value, cleanup: { _ in })
    }
}

/// Performs action on deinit.
public typealias DeinitAction = Resource<Void>
public extension Resource where T == Void {
    convenience init(_ onDeinit: @escaping () -> Void) {
        self.init((), cleanup: onDeinit)
    }
    
    static func onDeinit(_ action: @escaping () -> Void) -> DeinitAction {
        Resource(action)
    }
}

public extension Resource where T == URL {
    static func raii(location filesystemURL: URL) -> Resource {
        raii(filesystemURL) { try? FileManager.default.removeItem(at: $0) }
    }
    
    static func raii(temporaryFile: URL) throws -> Resource {
        let owned = TemporaryDirectory().uniqueFile(name: temporaryFile.lastPathComponent)
        try owned.createDirectoryTree()
        try FileManager.default.moveItem(at: temporaryFile, to: owned.url)
        return raii(location: owned.url)
    }
}

extension Resource: Equatable where T: Equatable {
    public static func == (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs.value == rhs.value
    }
}

extension Resource: Comparable where T: Comparable {
    public static func < (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        lhs.value < rhs.value
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Resource: Identifiable where T: Identifiable {
    public var id: T.ID { value.id }
}
