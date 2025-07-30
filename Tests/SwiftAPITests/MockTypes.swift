import Foundation
import Testing

@testable import SwiftAPICore

// MARK: - Helper Types

final class SendableBox<T>: @unchecked Sendable {
    var value: T
    private let lock = NSLock()

    init(_ value: T) {
        self.value = value
    }

    func withValue<R>(_ action: (inout T) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try action(&value)
    }
}

// MARK: - Mock Endpoint Types

struct MockGetEndpoint: Endpoint {
    static var path: String { "/mock/get" }
    static var method: EndpointMethod { EndpointMethod.GET }
}

struct MockPostEndpoint: Endpoint {
    var body: Body
    static var path: String { "/mock/post" }
    static var method: EndpointMethod { EndpointMethod.POST }

    init(body: Body) {
        self.body = body
    }
}

extension MockPostEndpoint {
    struct Body: CoSendable {
        let data: String
        init(data: String) { self.data = data }
    }

    struct ResponseContent: CoSendable {
        let result: String
        init(result: String) { self.result = result }
    }
}

struct MockStreamEndpoint: Endpoint {
    static var path: String { "/mock/stream" }
    static var method: EndpointMethod { EndpointMethod.POST }
}

extension MockStreamEndpoint {
    struct ResponseChunk: CoSendable {
        let chunk: String
        init(chunk: String) { self.chunk = chunk }
    }
}

// MARK: - Mock Route Types

struct MockRoute: RouteKind {
    var path: String = ""
    var method: EndpointMethod = EndpointMethod.GET
    var handler: @Sendable (MockRequest) async throws -> MockResponse = { _ in MockResponse() }

    init() {}
}

struct MockRequest: RouteRequestKind {
    let testUserId: UUID
    let bodyData: Data?
    let queryData: Data?

    var userId: UUID { testUserId }

    func decodedRequestBody<T: CoSendable>(_ type: T.Type) throws -> T {
        guard let data = bodyData else {
            return EmptyCodable() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func decodedRequestQuery<T: CoSendable>(_ type: T.Type) throws -> T {
        guard let data = queryData else {
            return EmptyCodable() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    init(userId: UUID = UUID(), bodyData: Data? = nil, queryData: Data? = nil) {
        self.testUserId = userId
        self.bodyData = bodyData
        self.queryData = queryData
    }
}

struct MockResponse: RouteResponseKind, @unchecked Sendable {
    let data: Any?

    static func fromCodable<T>(_ codable: T) -> MockResponse where T: CoSendable {
        return MockResponse(data: codable)
    }

    static func fromStream<S: AsyncSequence>(_ stream: S) -> MockResponse where S.Element: CoSendable {
        return MockResponse(data: stream)
    }

    init() {
        self.data = nil
    }

    init(data: Any?) {
        self.data = data
    }
}

// MARK: - Mock EndpointGroupProtocol

struct MockEndpointGroup: EndpointGroupProtocol {
    @RouteBuilder
    var routes: Routes {
        // Empty by default - individual tests can create specific mock groups
    }
}

struct MockEndpointGroupWithRoutes: EndpointGroupProtocol {
    let mockRoute: MockRoute

    @RouteBuilder
    var routes: Routes {
        mockRoute
    }

    init(route: MockRoute) {
        self.mockRoute = route
    }
}
