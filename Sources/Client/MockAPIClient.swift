import Foundation
import SwiftAPICore

public struct MockAPIClient<EP: Endpoint>: APIClientKind {
    var mockData: (@Sendable () -> EP.Content)?
    var mockStream: (@Sendable () -> AsyncThrowingStream<EP.Content, any Error>)?

    public init(
        mockData: @escaping @Sendable () -> EP.Content,
    ) {
        self.mockData = mockData
    }

    public init(
        mockStream: @escaping @Sendable () -> AsyncThrowingStream<EP.Content, any Error>
    ) {
        self.mockStream = mockStream
    }

    public func data<E>(on endpoint: E) async throws(APIClientError) -> E.Content where E: Endpoint {
        if let data = mockData!() as? E.Content {
            return data
        } else {
            print("MockAPIClient: mockData type mismatch or not set")
            fatalError("Mock data not set or type mismatch")
        }
    }

    public func accessToken() -> String {
        fatalError()
    }

    public func makeStream(request: URLRequest) -> AsyncThrowingStream<String, any Error> {
        mockStream!() as! AsyncThrowingStream<String, any Error>
    }

    public var baseURL: URL {
        fatalError()
    }

    public func handleServerResponseError(
        statusCode: Int,
        message: String,
        response: URLResponse
    ) async -> Bool {
        fatalError()
    }
}
