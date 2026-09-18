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
public enum BuildEnvironment: Sendable {
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
public enum RunEnvironment: Sendable {
    public enum Flags: Sendable {
        case isXCTesting
        case isRunFromXcode
        case isXcodePreview
        case isSimulator
    }
    
    public static let flags = {
        var flags: Set<Flags> = []
        if isXCTesting { flags.insert(.isXCTesting) }
        if isRunFromXcode { flags.insert(.isRunFromXcode) }
        if isXcodePreview { flags.insert(.isXcodePreview) }
        if isSimulator { flags.insert(.isSimulator) }
        return flags
    }()
    
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
    
    /// Runtime check if run from Xcode (Run / Test / Preview actions).
    ///
    /// Detection relies on environment variables Xcode injects into launched processes:
    /// - `OS_ACTIVITY_DT_MODE` (or `IDE_DISABLED_OS_ACTIVITY_DT_MODE` if the user disabled it in the scheme);
    /// - `__XCODE_BUILT_PRODUCTS_DIR_PATHS`, pointing to the build products directory.
    /// Note: those variables are inherited by child processes spawned by the app.
    public static let isRunFromXcode: Bool = {
        let env = ProcessInfo.processInfo.environment
        if env["OS_ACTIVITY_DT_MODE"].flatMap(parseBool) == true { return true }
        if env["IDE_DISABLED_OS_ACTIVITY_DT_MODE"] != nil { return true }
        if env["__XCODE_BUILT_PRODUCTS_DIR_PATHS"]?.isEmpty == false { return true }
        return false
    }()
    
    /// Runtime check if run as Xcode preview (SwiftUI / UIKit / AppKit `#Preview`).
    public static let isXcodePreview: Bool = {
        let env = ProcessInfo.processInfo.environment
        if env["XCODE_RUNNING_FOR_PREVIEWS"].flatMap(parseBool) == true { return true }
        
        // Xcode 16+ hosts previews inside `XCPreviewAgent` process.
        if ProcessInfo.processInfo.processName == "XCPreviewAgent" { return true }
        
        // Older Xcode versions build & run preview products from dedicated location.
        if Bundle.main.bundlePath.contains("/Xcode/UserData/Previews/") { return true }
        
        return false
    }()
    
    /// Runtime check if run in simulator.
    public static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }()
    
    private static func parseBool(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "1", "yes", "true": true
        case "0", "no", "false": false
        default: nil
        }
    }
}
