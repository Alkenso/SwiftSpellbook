//  MIT License
//
//  Copyright (c) 2026 Alkenso (Vladimir Vashurkin)
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

import Foundation

public final class ValueAsk<Request: Sendable, Response>: Sendable {
    public typealias Responder = ValueResponder<Request, Response>
    
    private let store = Synchronized<[UUID: Responder]>(.unfair)

    public init() {}
    
    public func attach(_ responder: Responder) -> Cancellation {
        let id = UUID()
        store[id] = responder
        return Cancellation { [weak store] in store?.removeValue(forKey: id) }
    }
    
    public func stream(_ request: Request) -> AsyncStream<Response> {
        let (stream, continuation) = AsyncStream<Response>.makeStream()
        Task {
            await withTaskGroup {
                for responder in store.read().values {
                    $0.addTask {
                        let response = await responder.ask(request)
                        continuation.yield(response)
                    }
                }
                await $0.waitForAll()
                continuation.finish()
            }
        }
        
        return stream
    }
    
    public func ask(_ request: Request, next: (Response) -> Bool = { _ in true }) async -> [Response] {
        var responses: [Response] = []
        for await response in stream(request) {
            responses.append(response)
            guard next(response) else { break }
        }
        return responses
    }
}

public struct ValueResponder<Request: Sendable, Response>: Sendable {
    public var name: String?
    public var process: @Sendable (Request) async -> sending Response
    
    public init(name: String? = nil, process: @escaping @Sendable (Request) async -> sending Response) {
        self.name = name
        self.process = process
    }
    
    public init(
        name: String? = nil,
        queue: DispatchQueue,
        process: @escaping @Sendable (Request, @escaping @Sendable (sending Response) -> Void) -> Void
    ) {
        self.init(name: name) { request in
            await withCheckedContinuation { continuation in
                queue.async {
                    process(request) { continuation.resume(returning: $0) }
                }
            }
        }
    }
    
    public func ask(_ request: Request) async -> Response {
        await process(request)
    }
}
