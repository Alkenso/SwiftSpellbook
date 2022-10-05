import SwiftConvenience
import SwiftConvenienceTestUtils
import XCTest

class ResourceTests: XCTestCase {
    func test_accessValue() {
        let resource = Resource<Int>.stub(10)
        
        XCTAssertEqual(resource.unsafeValue, 10)
        resource.withValue { XCTAssertEqual($0, 10) }
    }
    
    func test_forceCleanup() {
        let expectation = expectation(description: "Cleanup called")
        
        let resource = Resource<Int>(10) {
            XCTAssertEqual($0, 10)
            expectation.fulfill()
        }
        
        XCTAssertEqual(resource.unsafeValue, 10)
        resource.withValue { XCTAssertEqual($0, 10) }
        
        resource.cleanup()
        
        waitForExpectations()
    }
    
    func test_release() {
        let expectation = expectation(description: "Cleanup should not be called")
        expectation.isInverted = true
        
        let resource = Resource<Int>(10) { _ in
            expectation.fulfill()
        }
        
        XCTAssertEqual(resource.release(), 10)
        
        waitForExpectations()
    }
    
    func test_DeinitAction() {
        let exp = expectation(description: "Action on deinit.")
        DispatchQueue.global().async {
            _ = DeinitAction { exp.fulfill() }
        }
        
        waitForExpectations()
    }
    
    func test_pointer() {
        let exp = expectation(description: "Class deinited.")
        let ptr = UnsafeMutablePointer<Fulfill>.allocate(capacity: 1)
        ptr.initialize(to: .init(exp: exp))
        
        let resource = Resource.pointer(ptr)
        resource.cleanup()
        
        waitForExpectations()
    }
    
    func test_pointerFromValue() {
        let exp = expectation(description: "Class deinited.")
        let resource = Resource<UnsafeMutablePointer<Fulfill>>.pointer(value: Fulfill(exp: exp))
        resource.cleanup()
        
        waitForExpectations()
    }
    
    func test_bufferPointer() {
        let exp = expectation(description: "Class deinited.")
        exp.expectedFulfillmentCount = 3
        let ptr = UnsafeMutableBufferPointer<Fulfill>.allocate(capacity: 3)
        _ = ptr.initialize(from: [Fulfill(exp: exp), Fulfill(exp: exp), Fulfill(exp: exp)])
        
        let resource = Resource.pointer(ptr)
        resource.cleanup()
        
        waitForExpectations()
    }
    
    func test_bufferPointer_fromValue() {
        let exp = expectation(description: "Class deinited.")
        exp.expectedFulfillmentCount = 3
        let resource = Resource.pointer(values: [Fulfill(exp: exp), Fulfill(exp: exp), Fulfill(exp: exp)])
        resource.cleanup()
        
        waitForExpectations()
    }
}

private class Fulfill {
    let exp: XCTestExpectation
    init(exp: XCTestExpectation) { self.exp = exp }
    deinit { exp.fulfill() }
}
