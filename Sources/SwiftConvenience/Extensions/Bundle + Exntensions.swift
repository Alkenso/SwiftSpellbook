import Foundation


public extension Bundle {
    /// Bundle name. Value for Info.plist key "CFBundleNameKey".
    var name: String? { return value(for: kCFBundleNameKey as String) }

    /// Bundle short version. Value for Info.plist key "CFBundleShortVersionString".
    var shortVersion: String? { return value(for: "CFBundleShortVersionString") }

    /// Bundle version. Value for Info.plist key "CFBundleVersion".
    var version: String? { return value(for: "CFBundleVersion") }

    private func value(for key: String) -> String? {
        return object(forInfoDictionaryKey: key) as? String
    }
}

public extension Bundle {
    /// Searches for given resource inside the bundle and checks if the file exists.
    /// Equivalent to Bundle::url(forResource:withExtension) + FileManager::fileExists.
    /// - throws: NSError with code NSURLErrorFileDoesNotExist, domain NSURLErrorDomain if file does not exist.
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
