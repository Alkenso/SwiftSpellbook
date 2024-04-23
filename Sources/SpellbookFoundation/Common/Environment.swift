//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
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

import Foundation

/// Different indicators related to Application build environment.
public enum BuildEnvironment {
    /// Runtime check if run in debug mode.
    public static let isDebug: Bool = {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }()
}

/// Different indicators related to Application run environment.
public enum RunEnvironment {
    /// Runtime check if run inside XCTest bundle.
    public static let isXCTesting: Bool = {
        let envKeys = ["XCTestBundlePath", "XCTestConfigurationFilePath", "XCTestSessionIdentifier"]
        if ProcessInfo.processInfo.environment.keys.contains(where: envKeys.contains) { return true }
        
        if let path = ProcessInfo.processInfo.arguments.first {
            if path.lastPathComponent == "xctest" { return true }
            if path.pathExtension == "xctest" { return true }
        }
        
        if (try? NSException.catchingAll({
            if let observationCenterClass = NSClassFromString("XCTestObservationCenter") as? NSObject.Type,
               let observationCenter = observationCenterClass.perform(NSSelectorFromString("sharedTestObservationCenter")),
               let builtInObservers = observationCenter.takeUnretainedValue().perform(NSSelectorFromString("observers")),
               let builtInObserverArray = builtInObservers.takeUnretainedValue() as? [NSObject],
               let misuseObserverClass = NSClassFromString("XCTestMisuseObserver"),
               let misuseObserver = builtInObserverArray.first(where: { $0.isKind(of: misuseObserverClass) }),
               let currentCaseAny = misuseObserver.perform(NSSelectorFromString("currentTestCase")),
               let currentCase = currentCaseAny.takeUnretainedValue() as? NSObject,
               let testCaseClass = NSClassFromString("XCTestCase") {
                return currentCase.isKind(of: testCaseClass)
            } else {
                return false
            }
        })) == true {
            return true
        }
        
        return false
    }()
    
    /// Runtime check if run from Xcode.
    public static let isRunFromXcode: Bool = {
        guard let mode = ProcessInfo.processInfo.environment["OS_ACTIVITY_DT_MODE"] else { return false }
        return mode.uppercased() == "YES" || mode == "1"
    }()
    
    /// Runtime check if run as Xcode preview.
    public static let isXcodePreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"]?.isEmpty == false
    
    /// Runtime check if run in simulator.
    public static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }()
}
