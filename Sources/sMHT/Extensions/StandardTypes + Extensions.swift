import Foundation
import Darwin


// MARK: - Data

public extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

public extension Data {
    init<PODType>(pod: PODType) {
        var podCopy = pod
        self.init(pod: &podCopy)
    }

    init<PODType>(pod: inout PODType) {
        self.init(bytes: &pod, count: MemoryLayout<PODType>.size)
    }

    func pod<PODType>(of type: PODType.Type) -> PODType? {
        guard MemoryLayout<PODType>.size == count else { return nil }
        return withUnsafeBytes { $0.load(fromByteOffset: 0, as: type) }
    }
}


// MARK: - URL

public extension URL {
    init(staticString: StaticString) {
        guard let url = Self(string: "\(staticString)") else {
            preconditionFailure("Invalid static URL string: \(staticString)")
        }

        self = url
    }
}

public extension URL {
    enum FileType: CaseIterable {
        case blockSpecial
        case characterSpecial
        case fifo
        case regular
        case directory
        case symbolicLink
    }
    
    var fileType: FileType? {
        stat(self)
            .map(\.st_mode)
            .flatMap(FileType.init)
    }
}

extension URL.FileType {
    init?(_ mode: mode_t) {
        if let fileType = Self.allCases.first(where: { $0.stMode == mode & $0.stMode }) {
            self = fileType
        } else {
            return nil
        }
    }
    
    private var stMode: mode_t {
        switch self {
        case .blockSpecial: return S_IFBLK
        case .characterSpecial: return S_IFCHR
        case .fifo: return S_IFIFO
        case .regular: return S_IFREG
        case .directory: return S_IFDIR
        case .symbolicLink: return S_IFLNK
        }
    }
}


// MARK: - UUID

public extension UUID {
    init(staticString: StaticString) {
        guard let value = Self(uuidString: "\(staticString)") else {
            preconditionFailure("Invalid static UUID string: \(staticString)")
        }
        self = value
    }
}


// MARK: - Result

public extension Result {
    var value: Success? { try? get() }
    
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
