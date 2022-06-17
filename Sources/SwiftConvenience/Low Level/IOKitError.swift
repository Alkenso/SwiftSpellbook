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

#if os(macOS)
    import Foundation
    
    /// IOKit error type, wrapping codes from IOReturn.h
    public struct IOKitError {
        public init(_ code: Code, userInfo: [String: Any] = [:]) {
            self.code = code
            self.userInfo = userInfo
        }
        
        public let code: Code
        public let userInfo: [String: Any]
    }
    
    extension IOKitError: CustomNSError {
        public static var errorDomain: String { "IOKitErrorDomain" }
        public var errorCode: Int { Int(code.rawValue) }
        public var errorUserInfo: [String: Any] { userInfo }
    }
    
    public extension IOKitError {
        /// IOReturn.h error codes
        enum Code {
        /// OK
            case success
            
        /// general error
            case error
            
        /// can't allocate memory
            case noMemory
            
        /// resource shortage
            case noResources
            
        /// error during IPC
            case ipcError
            
        /// no such device
            case noDevice
            
        /// privilege violation
            case notPrivileged
            
        /// invalid argument
            case badArgument
            
        /// device read locked
            case lockedRead
            
        /// device write locked
            case lockedWrite
            
        /// exclusive access and device already open
            case exclusiveAccess
            
        /// sent/received messages had different msg_id
            case badMessageID
            
        /// unsupported function
            case unsupported
            
        /// misc. VM failure
            case vmError
            
        /// internal error
            case internalError
            
        /// General I/O error
            case ioError
            
        /// can't acquire lock
            case cannotLock
            
        /// device not open
            case notOpen
            
        /// read not supported
            case notReadable
            
        /// write not supported
            case notWritable
            
        /// alignment error
            case notAligned
            
        /// Media Error
            case badMedia
            
        /// device(s) still open
            case stillOpen
            
        /// rld failure
            case rldError
            
        /// DMA failure
            case dmaError
            
        /// Device Busy
            case busy
            
        /// I/O Timeout
            case timeout
            
        /// device offline
            case offline
            
        /// not ready
            case notReady
            
        /// device not attached
            case notAttached
            
        /// no DMA channels left
            case noChannels
            
        /// no space for data
            case noSpace
            
        /// port already exists
            case portExists
            
        /// can't wire down physical memory
            case cannotWire
            
        /// no interrupt attached
            case noInterrupt
            
        /// no DMA frames enqueued
            case noFrames
            
        /// oversized msg received on interrupt port
            case messageTooLarge
            
        /// not permitted
            case notPermitted
            
        /// no power to device
            case noPower
            
        /// media not present
            case noMedia
            
        // media not formatted
            case unformattedMedia
            
        /// no such mode
            case unsupportedMode
            
        /// data underrun
            case underrun
            
        /// data overrun
            case overrun
            
        /// the device is not working properly!
            case deviceError
            
        /// a completion routine is required
            case noCompletion
            
        /// operation aborted
            case aborted
            
        /// bus bandwidth would be exceeded
            case noBandwidth
            
        /// device not responding
            case notResponding
            
        /// isochronous I/O request for distant past!
            case isoTooOld
            
        /// isochronous I/O request for distant future
            case isoTooNew
            
        /// data was not found
            case notFound
            
        /// should never be seen
            case invalid
        }
    }
    
    extension IOKitError.Code: RawRepresentable {
        public typealias RawValue = IOReturn
        public init?(rawValue: IOReturn) {
            switch rawValue {
            case kIOReturnSuccess:
                self = .success
            case kIOReturnError:
                self = .error
            case kIOReturnNoMemory:
                self = .noMemory
            case kIOReturnNoResources:
                self = .noResources
            case kIOReturnIPCError:
                self = .ipcError
            case kIOReturnNoDevice:
                self = .noDevice
            case kIOReturnNotPrivileged:
                self = .notPrivileged
            case kIOReturnBadArgument:
                self = .badArgument
            case kIOReturnLockedRead:
                self = .lockedRead
            case kIOReturnLockedWrite:
                self = .lockedWrite
            case kIOReturnExclusiveAccess:
                self = .exclusiveAccess
            case kIOReturnBadMessageID:
                self = .badMessageID
            case kIOReturnUnsupported:
                self = .unsupported
            case kIOReturnVMError:
                self = .vmError
            case kIOReturnInternalError:
                self = .internalError
            case kIOReturnIOError:
                self = .ioError
            case kIOReturnCannotLock:
                self = .cannotLock
            case kIOReturnNotOpen:
                self = .notOpen
            case kIOReturnNotReadable:
                self = .notReadable
            case kIOReturnNotWritable:
                self = .notWritable
            case kIOReturnNotAligned:
                self = .notAligned
            case kIOReturnBadMedia:
                self = .badMedia
            case kIOReturnStillOpen:
                self = .stillOpen
            case kIOReturnRLDError:
                self = .rldError
            case kIOReturnDMAError:
                self = .dmaError
            case kIOReturnBusy:
                self = .busy
            case kIOReturnTimeout:
                self = .timeout
            case kIOReturnOffline:
                self = .offline
            case kIOReturnNotReady:
                self = .notReady
            case kIOReturnNotAttached:
                self = .notAttached
            case kIOReturnNoChannels:
                self = .noChannels
            case kIOReturnNoSpace:
                self = .noSpace
            case kIOReturnPortExists:
                self = .portExists
            case kIOReturnCannotWire:
                self = .cannotWire
            case kIOReturnNoInterrupt:
                self = .noInterrupt
            case kIOReturnNoFrames:
                self = .noFrames
            case kIOReturnMessageTooLarge:
                self = .messageTooLarge
            case kIOReturnNotPermitted:
                self = .notPermitted
            case kIOReturnNoPower:
                self = .noPower
            case kIOReturnNoMedia:
                self = .noMedia
            case kIOReturnUnformattedMedia:
                self = .unformattedMedia
            case kIOReturnUnsupportedMode:
                self = .unsupportedMode
            case kIOReturnUnderrun:
                self = .underrun
            case kIOReturnOverrun:
                self = .overrun
            case kIOReturnDeviceError:
                self = .deviceError
            case kIOReturnNoCompletion:
                self = .noCompletion
            case kIOReturnAborted:
                self = .aborted
            case kIOReturnNoBandwidth:
                self = .noBandwidth
            case kIOReturnNotResponding:
                self = .notResponding
            case kIOReturnIsoTooOld:
                self = .isoTooOld
            case kIOReturnIsoTooNew:
                self = .isoTooNew
            case kIOReturnNotFound:
                self = .notFound
            case kIOReturnInvalid:
                self = .invalid
            default:
                return nil
            }
        }
        
        public var rawValue: IOReturn {
            switch self {
            case .success:
                return kIOReturnSuccess
            case .error:
                return kIOReturnError
            case .noMemory:
                return kIOReturnNoMemory
            case .noResources:
                return kIOReturnNoResources
            case .ipcError:
                return kIOReturnIPCError
            case .noDevice:
                return kIOReturnNoDevice
            case .notPrivileged:
                return kIOReturnNotPrivileged
            case .badArgument:
                return kIOReturnBadArgument
            case .lockedRead:
                return kIOReturnLockedRead
            case .lockedWrite:
                return kIOReturnLockedWrite
            case .exclusiveAccess:
                return kIOReturnExclusiveAccess
            case .badMessageID:
                return kIOReturnBadMessageID
            case .unsupported:
                return kIOReturnUnsupported
            case .vmError:
                return kIOReturnVMError
            case .internalError:
                return kIOReturnInternalError
            case .ioError:
                return kIOReturnIOError
            case .cannotLock:
                return kIOReturnCannotLock
            case .notOpen:
                return kIOReturnNotOpen
            case .notReadable:
                return kIOReturnNotReadable
            case .notWritable:
                return kIOReturnNotWritable
            case .notAligned:
                return kIOReturnNotAligned
            case .badMedia:
                return kIOReturnBadMedia
            case .stillOpen:
                return kIOReturnStillOpen
            case .rldError:
                return kIOReturnRLDError
            case .dmaError:
                return kIOReturnDMAError
            case .busy:
                return kIOReturnBusy
            case .timeout:
                return kIOReturnTimeout
            case .offline:
                return kIOReturnOffline
            case .notReady:
                return kIOReturnNotReady
            case .notAttached:
                return kIOReturnNotAttached
            case .noChannels:
                return kIOReturnNoChannels
            case .noSpace:
                return kIOReturnNoSpace
            case .portExists:
                return kIOReturnPortExists
            case .cannotWire:
                return kIOReturnCannotWire
            case .noInterrupt:
                return kIOReturnNoInterrupt
            case .noFrames:
                return kIOReturnNoFrames
            case .messageTooLarge:
                return kIOReturnMessageTooLarge
            case .notPermitted:
                return kIOReturnNotPermitted
            case .noPower:
                return kIOReturnNoPower
            case .noMedia:
                return kIOReturnNoMedia
            case .unformattedMedia:
                return kIOReturnUnformattedMedia
            case .unsupportedMode:
                return kIOReturnUnsupportedMode
            case .underrun:
                return kIOReturnUnderrun
            case .overrun:
                return kIOReturnOverrun
            case .deviceError:
                return kIOReturnDeviceError
            case .noCompletion:
                return kIOReturnNoCompletion
            case .aborted:
                return kIOReturnAborted
            case .noBandwidth:
                return kIOReturnNoBandwidth
            case .notResponding:
                return kIOReturnNotResponding
            case .isoTooOld:
                return kIOReturnIsoTooOld
            case .isoTooNew:
                return kIOReturnIsoTooNew
            case .notFound:
                return kIOReturnNotFound
            case .invalid:
                return kIOReturnInvalid
            }
        }
    }
    
    extension IOKitError.Code: CustomStringConvertible {
        public var description: String {
            switch self {
            case .success:
                return "kIOReturnSuccess, short = 0x0, full = \(rawValueHex)"
            case .error:
                return "kIOReturnError, short = 0x2bc, full = \(rawValueHex)"
            case .noMemory:
                return "kIOReturnNoMemory, short = 0x2bd, full = \(rawValueHex)"
            case .noResources:
                return "kIOReturnNoResources, short = 0x2be, full = \(rawValueHex)"
            case .ipcError:
                return "kIOReturnIPCError, short = 0x2bf, full = \(rawValueHex)"
            case .noDevice:
                return "kIOReturnNoDevice, short = 0x2c0, full = \(rawValueHex)"
            case .notPrivileged:
                return "kIOReturnNotPrivileged, short = 0x2c1, full = \(rawValueHex)"
            case .badArgument:
                return "kIOReturnBadArgument, short = 0x2c2, full = \(rawValueHex)"
            case .lockedRead:
                return "kIOReturnLockedRead, short = 0x2c3, full = \(rawValueHex)"
            case .lockedWrite:
                return "kIOReturnLockedWrite, short = 0x2c4, full = \(rawValueHex)"
            case .exclusiveAccess:
                return "kIOReturnExclusiveAccess, short = 0x2c5, full = \(rawValueHex)"
            case .badMessageID:
                return "kIOReturnBadMessageID, short = 0x2c6, full = \(rawValueHex)"
            case .unsupported:
                return "kIOReturnUnsupported, short = 0x2c7, full = \(rawValueHex)"
            case .vmError:
                return "kIOReturnVMError, short = 0x2c8, full = \(rawValueHex)"
            case .internalError:
                return "kIOReturnInternalError, short = 0x2c9, full = \(rawValueHex)"
            case .ioError:
                return "kIOReturnIOError, short = 0x2ca, full = \(rawValueHex)"
            case .cannotLock:
                return "kIOReturnCannotLock, short = 0x2cc, full = \(rawValueHex)"
            case .notOpen:
                return "kIOReturnNotOpen, short = 0x2cd, full = \(rawValueHex)"
            case .notReadable:
                return "kIOReturnNotReadable, short = 0x2ce, full = \(rawValueHex)"
            case .notWritable:
                return "kIOReturnNotWritable, short = 0x2cf, full = \(rawValueHex)"
            case .notAligned:
                return "kIOReturnNotAligned, short = 0x2d0, full = \(rawValueHex)"
            case .badMedia:
                return "kIOReturnBadMedia, short = 0x2d1, full = \(rawValueHex)"
            case .stillOpen:
                return "kIOReturnStillOpen, short = 0x2d2, full = \(rawValueHex)"
            case .rldError:
                return "kIOReturnRLDError, short = 0x2d3, full = \(rawValueHex)"
            case .dmaError:
                return "kIOReturnDMAError, short = 0x2d4, full = \(rawValueHex)"
            case .busy:
                return "kIOReturnBusy, short = 0x2d5, full = \(rawValueHex)"
            case .timeout:
                return "kIOReturnTimeout, short = 0x2d6, full = \(rawValueHex)"
            case .offline:
                return "kIOReturnOffline, short = 0x2d7, full = \(rawValueHex)"
            case .notReady:
                return "kIOReturnNotReady, short = 0x2d8, full = \(rawValueHex)"
            case .notAttached:
                return "kIOReturnNotAttached, short = 0x2d9, full = \(rawValueHex)"
            case .noChannels:
                return "kIOReturnNoChannels, short = 0x2da, full = \(rawValueHex)"
            case .noSpace:
                return "kIOReturnNoSpace, short = 0x2db, full = \(rawValueHex)"
            case .portExists:
                return "kIOReturnPortExists, short = 0x2dd, full = \(rawValueHex)"
            case .cannotWire:
                return "kIOReturnCannotWire, short = 0x2de, full = \(rawValueHex)"
            case .noInterrupt:
                return "kIOReturnNoInterrupt, short = 0x2df, full = \(rawValueHex)"
            case .noFrames:
                return "kIOReturnNoFrames, short = 0x2e0, full = \(rawValueHex)"
            case .messageTooLarge:
                return "kIOReturnMessageTooLarge, short = 0x2e1, full = \(rawValueHex)"
            case .notPermitted:
                return "kIOReturnNotPermitted, short = 0x2e2, full = \(rawValueHex)"
            case .noPower:
                return "kIOReturnNoPower, short = 0x2e3, full = \(rawValueHex)"
            case .noMedia:
                return "kIOReturnNoMedia, short = 0x2e4, full = \(rawValueHex)"
            case .unformattedMedia:
                return "kIOReturnUnformattedMedia, short = 0x2e5, full = \(rawValueHex)"
            case .unsupportedMode:
                return "kIOReturnUnsupportedMode, short = 0x2e6, full = \(rawValueHex)"
            case .underrun:
                return "kIOReturnUnderrun, short = 0x2e7, full = \(rawValueHex)"
            case .overrun:
                return "kIOReturnOverrun, short = 0x2e8, full = \(rawValueHex)"
            case .deviceError:
                return "kIOReturnDeviceError, short = 0x2e9, full = \(rawValueHex)"
            case .noCompletion:
                return "kIOReturnNoCompletion, short = 0x2ea, full = \(rawValueHex)"
            case .aborted:
                return "kIOReturnAborted, short = 0x2eb, full = \(rawValueHex)"
            case .noBandwidth:
                return "kIOReturnNoBandwidth, short = 0x2ec, full = \(rawValueHex)"
            case .notResponding:
                return "kIOReturnNotResponding, short = 0x2ed, full = \(rawValueHex)"
            case .isoTooOld:
                return "kIOReturnIsoTooOld, short = 0x2ee, full = \(rawValueHex)"
            case .isoTooNew:
                return "kIOReturnIsoTooNew, short = 0x2ef, full = \(rawValueHex)"
            case .notFound:
                return "kIOReturnNotFound, short = 0x2f0, full = \(rawValueHex)"
            case .invalid:
                return "kIOReturnInvalid, short = 0x1, full = \(rawValueHex)"
            }
        }
        
        private var rawValueHex: String {
            String(format: "%02x", rawValue)
        }
    }
    
#endif
