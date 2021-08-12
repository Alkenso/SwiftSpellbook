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
public extension DeviceInfo {
    // Source: https://gist.github.com/adamawolf/3048717
    enum Model: Equatable {
        case iPhoneSimulator
        
        case iPhone
        case iPhone3G
        case iPhone3GS
        case iPhone4
        case iPhone4S
        case iPhone5
        case iPhone5C
        case iPhone5S
        case iPhone6
        case iPhone6Plus
        case iPhone6S
        case iPhone6SPlus
        case iPhoneSE
        case iPhone7
        case iPhone7Plus
        case iPhone8
        case iPhone8Plus
        case iPhoneX
        case iPhoneXS
        case iPhoneXSMax
        case iPhoneXR
        case iPhone11
        case iPhone11Pro
        case iPhone11ProMax
        case iPhoneSE2nd
        case iPhone12Mini
        case iPhone12
        case iPhone12Pro
        case iPhone12ProMax
        
        case iPod1
        case iPod2
        case iPod3
        case iPod4
        case iPod5
        case iPod6
        case iPod7
        
        case iPad
        case iPad3G
        case iPad2
        case iPad3
        case iPadMini
        case iPad4
        case iPadAir
        case iPadMiniRetina
        case iPadMini3
        case iPadMini4
        case iPadAir2
        case iPadPro_9_7
        case iPadPro_12_9
        case iPad5
        case iPadPro2
        case iPadPro_10_5
        case iPad6
        case iPad7
        case iPadPro_11
        case iPadPro3_12_9
        case iPadPro4_11
        case iPadPro4_12_9
        case iPadMini5
        case iPadAir3
        case iPad8
        case iPadAir4
        case iPadPro3_11
        case iPadPro5_12_9
        
        case other(String)
    }
    
    static var model: Model {
        switch modelName {
        case "i386", "x86_64", "arm64":
            return .iPhoneSimulator
        case "iPhone1,1":
            return .iPhone
        case "iPhone1,2":
            return .iPhone3G
        case "iPhone2,1":
            return .iPhone3GS
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":
            return .iPhone4
        case "iPhone4,1":
            return .iPhone4S
        case "iPhone5,1", "iPhone5,2":
            return .iPhone5
        case "iPhone5,3", "iPhone5,4":
            return .iPhone5C
        case "iPhone6,1", "iPhone6,2":
            return .iPhone5S
        case "iPhone7,2":
            return .iPhone6
        case "iPhone7,1":
            return .iPhone6Plus
        case "iPhone8,1":
            return .iPhone6S
        case "iPhone8,2":
            return .iPhone6SPlus
        case "iPhone8,4":
            return .iPhoneSE
        case "iPhone9,1", "iPhone9,3":
            return .iPhone7
        case "iPhone9,2", "iPhone9,4":
            return .iPhone7Plus
        case "iPhone10,1", "iPhone10,4":
            return .iPhone8
        case "iPhone10,2", "iPhone10,5":
            return .iPhone8Plus
        case "iPhone10,3", "iPhone10,6":
            return .iPhoneX
        case "iPhone11,2":
            return .iPhoneXS
        case "iPhone11,4", "iPhone11,6":
            return .iPhoneXSMax
        case "iPhone11,8":
            return .iPhoneXR
        case "iPhone12,1":
            return .iPhone11
        case "iPhone12,3":
            return .iPhone11Pro
        case "iPhone12,5":
            return .iPhone11ProMax
        case "iPhone12,8":
            return .iPhoneSE2nd
        case "iPhone13,1":
            return .iPhone12Mini
        case "iPhone13,2":
            return .iPhone12
        case "iPhone13,3":
            return .iPhone12Pro
        case "iPhone13,4":
            return .iPhone12ProMax
            
        case "iPod1,1": // 1st Gen iPod
            return .iPod1
        case "iPod2,1": // 2nd Gen iPod
            return .iPod2
        case "iPod3,1": // 3rd Gen iPod
            return .iPod3
        case "iPod4,1": // 4th Gen iPod
            return .iPod4
        case "iPod5,1": // 5th Gen iPod
            return .iPod5
        case "iPod7,1": // 6th Gen iPod
            return .iPod6
        case "iPod9,1": // 7th Gen iPod
            return .iPod7
            
        case "iPad1,1": // iPad
            return .iPad
        case "iPad1,2": // iPad 3G
            return .iPad3G
        case "iPad2,1": // 2nd Gen iPad
            return .iPad2
        case "iPad2,2": // 2nd Gen iPad GSM
            return .iPad2
        case "iPad2,3": // 2nd Gen iPad CDMA
            return .iPad2
        case "iPad2,4": // 2nd Gen iPad New Revision
            return .iPad2
        case "iPad3,1": // 3rd Gen iPad
            return .iPad3
        case "iPad3,2": // 3rd Gen iPad CDMA
            return .iPad3
        case "iPad3,3": // 3rd Gen iPad GSM
            return .iPad3
        case "iPad2,5": // iPad mini
            return .iPadMini
        case "iPad2,6": // iPad mini GSM+LTE
            return .iPadMini
        case "iPad2,7": // iPad mini CDMA+LTE
            return .iPadMini
        case "iPad3,4": // 4th Gen iPad
            return .iPad4
        case "iPad3,5": // 4th Gen iPad GSM+LTE
            return .iPad4
        case "iPad3,6": // 4th Gen iPad CDMA+LTE
            return .iPad4
        case "iPad4,1": // iPad Air (WiFi)
            return .iPadAir
        case "iPad4,2": // iPad Air (GSM+CDMA)
            return .iPadAir
        case "iPad4,3": // 1st Gen iPad Air (China)
            return .iPadAir
        case "iPad4,4": // iPad mini Retina (WiFi)
            return .iPadMiniRetina
        case "iPad4,5": // iPad mini Retina (GSM+CDMA)
            return .iPadMiniRetina
        case "iPad4,6": // iPad mini Retina (China)
            return .iPadMiniRetina
        case "iPad4,7": // iPad mini 3 (WiFi)
            return .iPadMini3
        case "iPad4,8": // iPad mini 3 (GSM+CDMA)
            return .iPadMini3
        case "iPad4,9": // iPad Mini 3 (China)
            return .iPadMini3
        case "iPad5,1": // iPad mini 4 (WiFi)
            return .iPadMini4
        case "iPad5,2": // 4th Gen iPad mini (WiFi+Cellular)
            return .iPadMini4
        case "iPad5,3": // iPad Air 2 (WiFi)
            return .iPadAir2
        case "iPad5,4": // iPad Air 2 (Cellular)
            return .iPadAir2
        case "iPad6,3": // iPad Pro (9.7 inch, WiFi)
            return .iPadPro_9_7
        case "iPad6,4": // iPad Pro (9.7 inch, WiFi+LTE)
            return .iPadPro_9_7
        case "iPad6,7": // iPad Pro (12.9 inch, WiFi)
            return .iPadPro_12_9
        case "iPad6,8": // iPad Pro (12.9 inch, WiFi+LTE)
            return .iPadPro_12_9
        case "iPad6,11": // iPad (2017)
            return .iPad5
        case "iPad6,12": // iPad (2017)
            return .iPad5
        case "iPad7,1": // iPad Pro 2nd Gen (WiFi)
            return .iPadPro2
        case "iPad7,2": //  iPad Pro 2nd Gen (WiFi+Cellular)
            return .iPadPro2
        case "iPad7,3": // iPad Pro 10.5-inch
            return .iPadPro_10_5
        case "iPad7,4": // iPad Pro 10.5-inch
            return .iPadPro_10_5
        case "iPad7,5": // iPad 6th Gen (WiFi)
            return .iPad6
        case "iPad7,6": // iPad 6th Gen (WiFi+Cellular)
            return .iPad6
        case "iPad7,11": // iPad 7th Gen 10.2-inch (WiFi)
            return .iPad7
        case "iPad7,12": // iPad 7th Gen 10.2-inch (WiFi+Cellular)
            return .iPad7
        case "iPad8,1": // iPad Pro 11 inch (WiFi)
            return .iPadPro_11
        case "iPad8,2": // iPad Pro 11 inch (1TB, WiFi)
            return .iPadPro_11
        case "iPad8,3": // iPad Pro 11 inch (WiFi+Cellular)
            return .iPadPro_11
        case "iPad8,4": // iPad Pro 11 inch (1TB, WiFi+Cellular)
            return .iPadPro_11
        case "iPad8,5": // iPad Pro 12.9 inch 3rd Gen (WiFi)
            return .iPadPro3_12_9
        case "iPad8,6": // iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)
            return .iPadPro3_12_9
        case "iPad8,7": // iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)
            return .iPadPro3_12_9
        case "iPad8,8": // iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)
            return .iPadPro3_12_9
        case "iPad8,9": // iPad Pro 11 inch 4th Gen (WiFi)
            return .iPadPro4_11
        case "iPad8,10": // iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            return .iPadPro4_11
        case "iPad8,11": // iPad Pro 12.9 inch 4th Gen (WiFi)
            return .iPadPro4_12_9
        case "iPad8,12": // iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)
            return .iPadPro4_12_9
        case "iPad11,1": // iPad mini 5th Gen (WiFi)
            return .iPadMini5
        case "iPad11,2": // iPad mini 5th Gen
            return .iPadMini5
        case "iPad11,3": // iPad Air 3rd Gen (WiFi)
            return .iPadAir3
        case "iPad11,4": // iPad Air 3rd Gen
            return .iPadAir3
        case "iPad11,6": // iPad 8th Gen (WiFi)
            return .iPad8
        case "iPad11,7": // iPad 8th Gen (WiFi+Cellular)
            return .iPad8
        case "iPad13,1": // iPad air 4th Gen (WiFi)
            return .iPadAir4
        case "iPad13,2": // iPad air 4th Gen (WiFi+Cellular)
            return .iPadAir4
        case "iPad13,4": // iPad Pro 11 inch 3rd Gen
            return .iPadPro3_11
        case "iPad13,5": // iPad Pro 11 inch 3rd Gen
            return .iPadPro3_11
        case "iPad13,6": // iPad Pro 11 inch 3rd Gen
            return .iPadPro3_11
        case "iPad13,7": // iPad Pro 11 inch 3rd Gen
            return .iPadPro3_11
        case "iPad13,8": // iPad Pro 12.9 inch 5th Gen
            return .iPadPro5_12_9
        case "iPad13,9": // iPad Pro 12.9 inch 5th Gen
            return .iPadPro5_12_9
        case "iPad13,10": // iPad Pro 12.9 inch 5th Gen
            return .iPadPro5_12_9
        case "iPad13,11": // iPad Pro 12.9 inch 5th Gen
            return .iPadPro5_12_9
            
        default:
            return .other(modelName)
        }
    }
    
    private static var modelName: String {
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
