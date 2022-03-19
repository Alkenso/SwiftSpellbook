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


public extension Process {
    /// Invoke given tool with arguments, returning executaion results in convenient form.
    /// - Warning: if the tool url is invalid, the function raises Objective-C NSInvalidArgumentException.
    static func launch(
        tool: URL,
        arguments: [String]
    ) -> (code: Int32, stdout: String, stderr: String) {
        let standardOutPipe = Pipe()
        let standardErrPipe = Pipe()
        
        let proc = Process()
        proc.launchPath = tool.path
        proc.arguments = arguments
        proc.standardOutput = standardOutPipe.fileHandleForWriting
        proc.standardError = standardErrPipe.fileHandleForWriting
        
        if let exception = NSException.catching({ proc.launch() }).exception {
            return (
                ENOENT,
                "",
                "Exception \(exception.name) ocurred. Reason: \(exception.reason ?? "<unknown>"). UserInfo: \(exception.userInfo?.description ?? "{}")"
            )
        }
        
        // We have to close our reference to the write side of the pipe so that the
        // termination of the child process triggers EOF on the read side.
        standardOutPipe.fileHandleForWriting.closeFile()
        standardErrPipe.fileHandleForWriting.closeFile()
        
        let standardOutData = standardOutPipe.fileHandleForReading.readDataToEndOfFile()
        standardOutPipe.fileHandleForReading.closeFile()
        
        let standardErrData = standardErrPipe.fileHandleForReading.readDataToEndOfFile()
        standardErrPipe.fileHandleForReading.closeFile()
        
        proc.waitUntilExit()
        
        return (
            proc.terminationStatus,
            String(data: standardOutData, encoding: .utf8) ?? "",
            String(data: standardErrData, encoding: .utf8) ?? ""
        )
    }
}

#endif
