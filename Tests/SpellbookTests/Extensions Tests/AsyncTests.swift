import SpellbookFoundation

import Testing

@Suite
struct AsyncSequenceExtensionsTests {
    @Test
    @MainActor
    func forEach() async throws {
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.yield(20)
            continuation.yield(30)
            continuation.finish()
        }
        var values: [Int] = []

        try await stream.forEach {
            MainActor.preconditionIsolated()
            values.append($0)
        }.value

        #expect(values == [10, 20, 30])
    }

    @Test
    func forEach_failure() async {
        enum ExpectedError: Error {
            case failure
        }
        
        let stream = AsyncThrowingStream<Int, any Error> { continuation in
            continuation.yield(10)
            continuation.finish(throwing: ExpectedError.failure)
        }
        nonisolated(unsafe) var values: [Int] = []
        let task = stream.forEach { values.append($0) }
        await #expect(throws: ExpectedError.self) {
            try await task.value
        }
        #expect(values == [10])
    }

    @Test
    @MainActor
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func forEach_nonThrowingInheritsIsolation() async {
        let stream = AsyncStream<Int> { continuation in
            continuation.yield(10)
            continuation.finish()
        }
        var values: [Int] = []
        await stream.forEach {
            MainActor.preconditionIsolated()
            values.append($0)
        }.value

        #expect(values == [10])
    }
}
