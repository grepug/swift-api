import Foundation
import Testing

@testable import SwiftAPICore

@Suite("RouteKind Protocol Tests")
struct RouteKindTests {

    @Suite("Route Configuration")
    struct RouteConfigurationTests {
        @Test("Default timeout value")
        func defaultTimeoutValue() {
            let route = MockRoute()
            #expect(route.timeout == 60.0)
        }

        @Test("Block endpoint configuration")
        func blockEndpointConfiguration() async throws {
            let route = MockRoute()

            let configuredRoute = route.block(MockPostEndpoint.self) { context in
                #expect(context.request.userId != UUID())
                #expect(context.body.data == "test")
                return MockPostEndpoint.ResponseContent(result: "success")
            }

            #expect(configuredRoute.path == "/mock/post")
            #expect(configuredRoute.method == EndpointMethod.POST)
        }

        @Test("Stream endpoint configuration")
        func streamEndpointConfiguration() async throws {
            let route = MockRoute()

            let configuredRoute = route.stream(MockStreamEndpoint.self) { context in
                AsyncStream<MockStreamEndpoint.ResponseChunk> { continuation in
                    continuation.yield(MockStreamEndpoint.ResponseChunk(chunk: "chunk1"))
                    continuation.yield(MockStreamEndpoint.ResponseChunk(chunk: "chunk2"))
                    continuation.finish()
                }
            }

            #expect(configuredRoute.path == "/mock/stream")
            #expect(configuredRoute.method == EndpointMethod.POST)
        }

        @Test("RequestContext creation and usage")
        func requestContextCreation() throws {
            let testUserId = UUID()
            let bodyData = try JSONEncoder().encode(MockPostEndpoint.RequestBody(data: "test"))
            let request = MockRequest(userId: testUserId, bodyData: bodyData)

            let context = RequestContext(
                request: request,
                query: EmptyCodable(),
                body: MockPostEndpoint.RequestBody(data: "test")
            )

            #expect(context.request.userId == testUserId)
            #expect(context.body.data == "test")
        }

        @Test("Handler execution flow")
        func handlerExecutionFlow() async throws {
            var route = MockRoute()
            let handlerExecuted = SendableBox(false)

            route.handler = { request in
                handlerExecuted.value = true
                return MockResponse()
            }

            let request = MockRequest()
            let response = try await route.handler(request)

            #expect(handlerExecuted.value == true)
            #expect(response.data == nil)
        }
    }
}
