#if Server
    import ConcurrencyUtils
    import Vapor

    extension Response {
        static func codable2<T: Codable>(_ result: T, status: HTTPResponseStatus = .ok) -> Self {
            let response = Self(status: status)
            let content = EndpointResponseContainer(result: result)
            let data = try! JSONEncoder().encode(content)
            response.body = .init(data: data)
            response.headers.add(name: .contentType, value: "application/json")
            return response
        }

        static func codableStream<S: AsyncSequence>(_ stream: S, timeout: TimeInterval = 60, completion: (@Sendable () async throws -> Void)? = nil) -> Self
        where S.Element: Output, S: Sendable {
            let response = Self(status: .ok)
            let body = Response.Body { writer in
                Task {
                    do {
                        try await withTimeoutThrowingHandler(timeout: .seconds(timeout)) {
                            for try await element in stream {
                                let response = ServerStreamResponseContent(chunk: element, finished: false)
                                let data = try JSONEncoder().encode(response)
                                let string = String(data: data, encoding: .utf8)!
                                let finalString = "data: \(string)\r\n\r\n"

                                do {
                                    try await writer.write(.buffer(.init(string: finalString))).get()
                                } catch {
                                    // FIXME: Handle the error
                                    print("Error writing to response body: \(error)")
                                    throw error
                                }
                            }

                            try await writer.write(.end).get()
                        }
                    } catch {
                        if let error = error as? ConcurrencyError {
                            switch error {
                            case .timeout:
                                try await writer.write(.error(Abort(.requestTimeout, reason: "makeCodableStream timeout"))).get()
                            default:
                                break
                            }
                        }

                        // FIXME: instead of writing/throwing an error, we should write a proper error message to the client
                        try await writer.write(.error(Abort(.internalServerError, reason: error.localizedDescription))).get()
                    }

                    try await completion?()
                }
            }

            response.body = body
            response.headers.add(name: .contentType, value: "text/event-stream")

            return response
        }
    }

    public struct ServerStreamResponseContent<T: Output>: Codable, Sendable {
        public let chunk: T
        public let finished: Bool

        public init(chunk: T, finished: Bool) {
            self.chunk = chunk
            self.finished = finished
        }
    }

    public typealias Output = Codable & Sendable & Hashable
#endif
