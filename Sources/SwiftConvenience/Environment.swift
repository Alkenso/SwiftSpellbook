//
//  File.swift
//  
//
//  Created by Alkenso (Vladimir Vashurkin) on 03.08.2021.
//

import Foundation


public enum BuildEnvironment {
    public static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    public static let isXCTesting: Bool = NSClassFromString("XCTestProbe") != nil
}
