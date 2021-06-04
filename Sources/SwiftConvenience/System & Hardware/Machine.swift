//
//  File.swift
//  
//
//  Created by Alkenso (Vladimir Vashurkin) on 04.06.2021.
//

import Foundation


public enum Machine {}

#if os(macOS)
public extension Machine {
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
