import SpellbookFoundation
import SpellbookTestUtils
import XCTest

class ResourceTests: XCTestCase {
    func test_accessValue() {
        let resource = Resource<Int>.stub(10)
        
        XCTAssertEqual(resource.wrappedValue, 10)
        resource.withValue { XCTAssertEqual($0, 10) }
    }
    
    func test_reset() {
        func test(free: Bool, newValue: Int?, cleanupCalls: Int) {
            withScope {
                let expectation = expectation(description: "Cleanup should be called \(cleanupCalls) times only")
                if cleanupCalls > 0 {
                    expectation.expectedFulfillmentCount = cleanupCalls
                } else {
                    expectation.isInverted = true
                }
                
                let resource = Resource<Int>(10) { _ in
                    expectation.fulfill()
                }
                
                XCTAssertEqual(resource.reset(free: free, to: newValue), 10)
                XCTAssertEqual(resource.wrappedValue, newValue ?? 10)
            }
            
            waitForExpectations()
        }
        
        test(free: true, newValue: nil, cleanupCalls: 1)
        test(free: false, newValue: nil, cleanupCalls: 0)
        test(free: true, newValue: 20, cleanupCalls: 2)
        test(free: false, newValue: 20, cleanupCalls: 1)
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
        resource.reset()
        
        waitForExpectations()
    }
    
    func test_pointerFromValue() {
        let exp = expectation(description: "Class deinited.")
        let resource = Resource<UnsafeMutablePointer<Fulfill>>.pointer(value: Fulfill(exp: exp))
        resource.reset()
        
        waitForExpectations()
    }
    
    func test_bufferPointer() {
        let exp = expectation(description: "Class deinited.")
        exp.expectedFulfillmentCount = 3
        let ptr = UnsafeMutableBufferPointer<Fulfill>.allocate(capacity: 3)
        _ = ptr.initialize(from: [Fulfill(exp: exp), Fulfill(exp: exp), Fulfill(exp: exp)])
        
        let resource = Resource.pointer(ptr)
        resource.reset()
        
        waitForExpectations()
    }
    
    func test_bufferPointer_fromValue() {
        let exp = expectation(description: "Class deinited.")
        exp.expectedFulfillmentCount = 3
        let resource = Resource.pointer(values: [Fulfill(exp: exp), Fulfill(exp: exp), Fulfill(exp: exp)])
        resource.reset()
        
        waitForExpectations()
    }
}

private class Fulfill {
    let exp: XCTestExpectation
    init(exp: XCTestExpectation) { self.exp = exp }
    deinit { exp.fulfill() }
}
