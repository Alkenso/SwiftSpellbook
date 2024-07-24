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

public enum DeviceInfo {}

// MARK: - macOS

#if os(macOS)
public extension DeviceInfo {
    /// Machine's UUID. Same as 'Hardware UUID' found in 'About this Mac'.
    static func hardwareUUID() throws -> UUID {
        let property = try search(property: kIOPlatformUUIDKey)
        guard let uuid = UUID(uuidString: property) else {
            throw IOKitError(
                .badArgument,
                userInfo: [NSDebugDescriptionErrorKey: "Failed to create UUID from string \"\(property)\""]
            )
        }
        
        return uuid
    }
    
    /// Machine's serial number. Same as 'Serial Number' found in 'About this Mac'.
    static func serialNumber() throws -> String {
        try search(property: kIOPlatformSerialNumberKey)
    }
    
    private static func search(property name: String) throws -> String {
        let platformExpert = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard platformExpert != IO_OBJECT_NULL else {
            throw IOKitError(
                .noDevice,
                userInfo: [NSDebugDescriptionErrorKey: "IOServiceGetMatchingService: failed to match IOPlatformExpertDevice"]
            )
        }
        
        let property = IORegistryEntryCreateCFProperty(
            platformExpert,
            name as CFString,
            kCFAllocatorDefault,
            0
        )
        
        guard let value = property?.takeRetainedValue() as? String else {
            throw IOKitError(
                .notFound,
                userInfo: [NSDebugDescriptionErrorKey: "IORegistryEntryCreateCFProperty: failed to get property \(name)"]
            )
        }
        
        return value
    }
}
#endif

// MARK: - iOS

#if os(iOS)
extension DeviceInfo {
    /// Models: https://gist.github.com/adamawolf/3048717
    public static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
#endif
