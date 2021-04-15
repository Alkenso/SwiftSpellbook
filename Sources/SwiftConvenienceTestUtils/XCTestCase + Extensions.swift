import XCTest


public extension XCTestCase {
    static var waitTimeout: TimeInterval = 0.5
    
    static var testBundle: Bundle {
        return Bundle(for: Self.self)
    }
    
    var testBundle: Bundle {
        Self.testBundle
    }
    
    @discardableResult
    func waitForExpectations(timeout: TimeInterval = XCTestCase.waitTimeout) -> Error? {
        var error: Error?
        waitForExpectations(timeout: timeout, handler: {
            error = $0
        })
        
        return error
    }
}
