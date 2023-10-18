import Foundation
import SpellbookFoundation

public enum Testing {
    public enum Web {
        public static let urlPath = "/get/stuff"
        public static let urlScheme = "https"
        public static let urlHost = "some.company.com"
        public static let url = URL(staticString: "https://some.company.com/get/stuff")
    }
    
    public enum Files {
        public static func url(_ index: Int, isDirectory: Bool = false) -> URL {
            URL(
                fileURLWithPath: "/path/to/\(index).txt",
                isDirectory: isDirectory
            )
        }
    }
}
