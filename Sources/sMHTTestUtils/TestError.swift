//
//  File.swift
//  
//
//  Created by Alkenso (Vladimir Vashurkin) on 15.04.2021.
//

import Foundation


public struct TestError: Error {
    public let description: String
    public let underlyingError: Error?
    
    
    public init() {
        self.init("Any test error.")
    }
    
    public init(_ description: String, underlying underlyingError: Error? = nil) {
        self.description = description
        self.underlyingError = underlyingError
    }
}
