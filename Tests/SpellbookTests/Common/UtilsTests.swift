import SpellbookFoundation

import XCTest

class UtilsTests: XCTestCase {
    func test_updateValue() {
        struct Foo {
            var value = 10
        }
        XCTAssertEqual(updateValue(Foo(), at: \.value, with: 20).value, 20)
        XCTAssertEqual(updateValue(Foo(), using: { $0.value = 20 }).value, 20)
        XCTAssertEqual(updateValue(Foo(), using: { $0 = .init(value: 20) }).value, 20)
     }
    
    func test_task_cancel() async {
        let task = Task.detached { try await Task.sleep(forTimeInterval: .seconds(3)) }
        try? await Task.sleep(forTimeInterval: 0.01)
        task.cancel()
        let result = await task.result
        XCTAssertThrowsError(try result.get())
    }
}
