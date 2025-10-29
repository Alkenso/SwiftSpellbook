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
    
    public var code: Code
    public nonisolated(unsafe) var userInfo: [String: Any]
}

extension IOKitError: CustomNSError {
    public static var errorDomain: String { "IOKitErrorDomain" }
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String: Any] { userInfo }
}

extension IOKitError {
    /// IOReturn.h error codes
    public struct Code: RawRepresentable, Hashable, Sendable {
        public var rawValue: IOReturn
        public init(rawValue: IOReturn) { self.rawValue = rawValue }
        
        /// OK.
        public static let success = Self(rawValue: kIOReturnSuccess)
        
        /// general error.
        public static let error = Self(rawValue: kIOReturnError)
        
        /// can't allocate memory.
        public static let noMemory = Self(rawValue: kIOReturnNoMemory)
        
        /// resource shortage.
        public static let noResources = Self(rawValue: kIOReturnNoResources)
        
        /// error during IPC.
        public static let ipcError = Self(rawValue: kIOReturnIPCError)
        
        /// no such device.
        public static let noDevice = Self(rawValue: kIOReturnNoDevice)
        
        /// privilege violation.
        public static let notPrivileged = Self(rawValue: kIOReturnNotPrivileged)
        
        /// invalid argument.
        public static let badArgument = Self(rawValue: kIOReturnBadArgument)
        
        /// device read locked.
        public static let lockedRead = Self(rawValue: kIOReturnLockedRead)
        
        /// device write locked.
        public static let lockedWrite = Self(rawValue: kIOReturnLockedWrite)
        
        /// exclusive access and device already open.
        public static let exclusiveAccess = Self(rawValue: kIOReturnExclusiveAccess)
        
        /// sent/received messages had different msg_id.
        public static let badMessageID = Self(rawValue: kIOReturnBadMessageID)
        
        /// unsupported function.
        public static let unsupported = Self(rawValue: kIOReturnUnsupported)
        
        /// misc. VM failure.
        public static let vmError = Self(rawValue: kIOReturnVMError)
        
        /// internal error.
        public static let internalError = Self(rawValue: kIOReturnInternalError)
        
        /// General I/O error.
        public static let ioError = Self(rawValue: kIOReturnIOError)
        
        /// can't acquire lock.
        public static let cannotLock = Self(rawValue: kIOReturnCannotLock)
        
        /// device not open.
        public static let notOpen = Self(rawValue: kIOReturnNotOpen)
        
        /// read not supported.
        public static let notReadable = Self(rawValue: kIOReturnNotReadable)
        
        /// write not supported.
        public static let notWritable = Self(rawValue: kIOReturnNotWritable)
        
        /// alignment error.
        public static let notAligned = Self(rawValue: kIOReturnNotAligned)
        
        /// Media Error.
        public static let badMedia = Self(rawValue: kIOReturnBadMedia)
        
        /// device(s) still open.
        public static let stillOpen = Self(rawValue: kIOReturnStillOpen)
        
        /// rld failure.
        public static let rldError = Self(rawValue: kIOReturnRLDError)
        
        /// DMA failure.
        public static let dmaError = Self(rawValue: kIOReturnDMAError)
        
        /// Device Busy.
        public static let busy = Self(rawValue: kIOReturnBusy)
        
        /// I/O Timeout.
        public static let timeout = Self(rawValue: kIOReturnTimeout)
        
        /// device offline.
        public static let offline = Self(rawValue: kIOReturnOffline)
        
        /// not ready.
        public static let notReady = Self(rawValue: kIOReturnNotReady)
        
        /// device not attached.
        public static let notAttached = Self(rawValue: kIOReturnNotAttached)
        
        /// no DMA channels left.
        public static let noChannels = Self(rawValue: kIOReturnNoChannels)
        
        /// no space for data.
        public static let noSpace = Self(rawValue: kIOReturnNoSpace)
        
        /// port already exists.
        public static let portExists = Self(rawValue: kIOReturnPortExists)
        
        /// can't wire down physical memory.
        public static let cannotWire = Self(rawValue: kIOReturnCannotWire)
        
        /// no interrupt attached.
        public static let noInterrupt = Self(rawValue: kIOReturnNoInterrupt)
        
        /// no DMA frames enqueued.
        public static let noFrames = Self(rawValue: kIOReturnNoFrames)
        
        /// oversized msg received on interrupt port.
        public static let messageTooLarge = Self(rawValue: kIOReturnMessageTooLarge)
        
        /// not permitted.
        public static let notPermitted = Self(rawValue: kIOReturnNotPermitted)
        
        /// no power to device.
        public static let noPower = Self(rawValue: kIOReturnNoPower)
        
        /// media not present.
        public static let noMedia = Self(rawValue: kIOReturnNoMedia)
        
        /// media not formatted.
        public static let unformattedMedia = Self(rawValue: kIOReturnUnformattedMedia)
        
        /// no such mode.
        public static let unsupportedMode = Self(rawValue: kIOReturnUnsupportedMode)
        
        /// data underrun.
        public static let underrun = Self(rawValue: kIOReturnUnderrun)
        
        /// data overrun.
        public static let overrun = Self(rawValue: kIOReturnOverrun)
        
        /// the device is not working properly!.
        public static let deviceError = Self(rawValue: kIOReturnDeviceError)
        
        /// a completion routine is required.
        public static let noCompletion = Self(rawValue: kIOReturnNoCompletion)
        
        /// operation aborted.
        public static let aborted = Self(rawValue: kIOReturnAborted)
        
        /// bus bandwidth would be exceeded.
        public static let noBandwidth = Self(rawValue: kIOReturnNoBandwidth)
        
        /// device not responding.
        public static let notResponding = Self(rawValue: kIOReturnNotResponding)
        
        /// isochronous I/O request for distant past!.
        public static let isoTooOld = Self(rawValue: kIOReturnIsoTooOld)
        
        /// isochronous I/O request for distant future.
        public static let isoTooNew = Self(rawValue: kIOReturnIsoTooNew)
        
        /// data was not found.
        public static let notFound = Self(rawValue: kIOReturnNotFound)
        
        /// should never be seen.
        public static let invalid = Self(rawValue: kIOReturnInvalid)
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
        default:
            return "Unknown, value = \(rawValueHex)"
        }
    }
    
    private var rawValueHex: String {
        String(format: "%02x", rawValue)
    }
}

#endif
