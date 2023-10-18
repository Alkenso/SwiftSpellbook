//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
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

import SpellbookFoundation

import Foundation

public struct HTTPRequest {
    public var url: String
    public var method: Method
    public var port: UInt16?
    
    public var query: [QueryItem: String] = [:]
    public var headers: [Header: HeaderValue] = [:]
    public var body: Body?
    
    public init(urlString: String, method: Method) {
        self.url = urlString
        self.method = method
    }
    
    public init(url: URL, method: Method) {
        self.init(urlString: url.absoluteString, method: method)
    }
}

extension HTTPRequest {
    public struct Method: RawRepresentable, Hashable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
}

extension HTTPRequest.Method {
    public static let get = Self(rawValue: "GET")
    public static let post = Self(rawValue: "POST")
}
    
extension HTTPRequest {
    public struct QueryItem: RawRepresentable, Hashable, ExpressibleByStringLiteral {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
    }
}
 
extension HTTPRequest {
    public struct Header: RawRepresentable, Hashable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
    
    public struct HeaderValue: RawRepresentable, Hashable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
}

extension HTTPRequest.Header {
    public static let userAgent = Self(rawValue: "user-agent")
}

extension HTTPRequest.Header: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

extension HTTPRequest.HeaderValue {
    public static func authorization(_ type: HTTPRequest.AuthorizationType, _ token: String) -> Self {
        .init(rawValue: "\(type.rawValue) \(token)")
    }
}

extension HTTPRequest.HeaderValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

extension HTTPRequest.HeaderValue: ExpressibleByStringInterpolation {
    public init(stringInterpolation: DefaultStringInterpolation) { self.rawValue = stringInterpolation.description }
}

extension HTTPRequest {
    public struct AuthorizationType: RawRepresentable, Hashable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
}

extension HTTPRequest.AuthorizationType: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

extension HTTPRequest.AuthorizationType: ExpressibleByStringInterpolation {
    public init(stringInterpolation: DefaultStringInterpolation) { self.rawValue = stringInterpolation.description }
}

extension HTTPRequest {
    public struct Body {
        internal let data: () throws -> Data
        internal let contentType: String?
        
        public init(contentType: String?, data: @escaping () throws -> Data) {
            self.data = data
            self.contentType = contentType
        }
    }
}

extension HTTPRequest.Body {
    private static let contentTypePlist = "application/x-apple-plist"
    private static let contentTypeJSON = "application/json"
    
    private init<T>(value: T, encoder: ObjectEncoder<T>, contentType: String) {
        self.init(contentType: contentType) { try encoder.encode(value) }
    }
    
    public static func foundation(json obj: Any, options: JSONSerialization.WritingOptions = []) -> Self {
        .init(value: obj, encoder: .foundationJSON(options: options), contentType: contentTypeJSON)
    }
    
    public static func foundation(plist obj: Any, format: PropertyListSerialization.PropertyListFormat = .xml) -> Self {
        .init(value: obj, encoder: .foundationPlist(format: format), contentType: contentTypePlist)
    }
    
    public static func codable<T: Encodable>(json obj: T, formatting: JSONEncoder.OutputFormatting = []) -> Self {
        .init(value: obj, encoder: .json(formatting: formatting), contentType: contentTypeJSON)
    }
    
    public static func codable<T: Encodable>(plist obj: T, format: PropertyListSerialization.PropertyListFormat = .xml) -> Self {
        .init(value: obj, encoder: .plist(format: format), contentType: contentTypePlist)
    }
    
    public static func data(_ data: Data, contentType: String?) -> Self {
        .init(contentType: contentType, data: { data })
    }
}

extension HTTPRequest {
    public func urlRequest() throws -> URLRequest {
        guard var components = URLComponents(string: url) else {
            fatalError()
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key.rawValue, value: $0.value) }
        }
        if let port  {
            components.port = Int(port)
        }
        guard let url = components.url else {
            fatalError()
        }
        
        var urlRequest = URLRequest(url: url)
        headers.forEach {
            urlRequest.setValue($0.value.rawValue, forHTTPHeaderField: $0.key.rawValue)
        }
        urlRequest.httpMethod = method.rawValue
        if let body {
            urlRequest.httpBody = try Result { try body.data() }
                .mapError { $0 }
                .get()
            if let contentType = body.contentType {
                urlRequest.addValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        }
        
        return urlRequest
    }
}
