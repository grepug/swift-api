import Foundation
import SwiftAPICore

public struct MockAPIClient<K: Sendable & Codable>: APIClientKind {
    
    var mockedData: K
    
    public init(mockedData: K) {
        self.mockedData = mockedData
    }
    
    public func data<T, Body, Query, Error>(_ path: String, method: EndpointMethod, query: Query, body: Body, errorType: Error.Type, decodingAs type: T.Type) async throws(APIClientError<Error>) -> T where T : Decodable, T : Encodable, Body : Encodable, Query : Encodable, Error : CodableError {
        return mockedData as! T
    }

    public func accessToken() -> String {
        fatalError()
    }
    
    public func makeStream(request: URLRequest) -> AsyncThrowingStream<String, any Error> {
        fatalError()
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
