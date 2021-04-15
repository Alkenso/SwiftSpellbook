import Foundation


public extension Bundle {
    var name: String? { return value(for: kCFBundleNameKey as String) }

    var shortVersion: String? { return value(for: "CFBundleShortVersionString") }

    var version: String? { return value(for: "CFBundleVersion") }

    private func value(for key: String) -> String? {
        return object(forInfoDictionaryKey: key) as? String
    }
}

public extension Bundle {
    func existingURL(forResource name: String, withExtension ext: String?) throws -> URL {
        guard let url = url(forResource: name, withExtension: ext),
              FileManager.default.fileExists(atPath: url.path)
        else {
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorFileDoesNotExist,
                userInfo: [
                    NSDebugDescriptionErrorKey: "Resource file \(name) not found."
                ]
            )
        }
        
        return url
    }
}
