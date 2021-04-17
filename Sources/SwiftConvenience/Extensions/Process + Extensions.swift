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
        
        proc.launch()
        
        // We have to close our reference to the write side of the pipe so that the
        // termination of the child process triggers EOF on the read side.
        standardOutPipe.fileHandleForWriting.closeFile()
        standardErrPipe.fileHandleForWriting.closeFile()
        
        proc.waitUntilExit()
        
        let standardOutData = standardOutPipe.fileHandleForReading.readDataToEndOfFile()
        standardOutPipe.fileHandleForReading.closeFile()
        
        let standardErrData = standardErrPipe.fileHandleForReading.readDataToEndOfFile()
        standardErrPipe.fileHandleForReading.closeFile()
        
        return (
            proc.terminationStatus,
            String(data: standardOutData, encoding: .utf8) ?? "",
            String(data: standardErrData, encoding: .utf8) ?? ""
        )
    }
}
