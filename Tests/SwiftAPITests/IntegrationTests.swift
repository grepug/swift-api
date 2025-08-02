import Foundation
import Testing

@testable import SwiftAPICore

@Suite("SwiftAPICore Integration Tests")
struct IntegrationTests {

    @Suite("End-to-End Workflows")
    struct EndToEndWorkflowTests {
        @Test("Complete endpoint to route workflow")
        func completeEndpointToRouteWorkflow() async throws {
            // Create a mock endpoint group with actual routes
            var mockRoute = MockRoute()
            mockRoute = mockRoute.block(MockPostEndpoint.self) { context in
                #expect(context.body.data == "integration test")
                return MockPostEndpoint.Content(result: "success")
            }

            let mockGroup = MockEndpointGroupWithRoutes(route: mockRoute)

            #expect(mockGroup.finalRoutes.count == 1)
            #expect(mockGroup.finalRoutes[0].path == "/mock/post")
            #expect(mockGroup.finalRoutes[0].method == EndpointMethod.POST)
        }

        @Test("RouteBuilder with EndpointGroupProtocol integration")
        func routeBuilderWithEndpointGroupIntegration() {
            // Test that @RouteBuilder works properly in EndpointGroupProtocol context
            let route = MockRoute()
            let group = MockEndpointGroupWithRoutes(route: route)

            // Should combine routes correctly
            #expect(group.finalRoutes.count == 1)

            // Test route builder functionality
            let emptyRoutes = RouteBuilder.buildBlock()
            let singleRoute = RouteBuilder.buildBlock(MockRoute())

            #expect(emptyRoutes.isEmpty)
            #expect(singleRoute.count == 1)
        }

        @Test("RequestContext with real endpoint data flow")
        func requestContextWithRealEndpointDataFlow() throws {
            let testUserId = UUID()
            let requestBody = MockPostEndpoint.Body(data: "context test")
            let bodyData = try JSONEncoder().encode(requestBody)

            let request = MockRequest(userId: testUserId, bodyData: bodyData)

            // Test RequestContext creation with real data
            let context = RequestContext(
                request: request,
                query: EmptyCodable(),
                body: requestBody
            )

            #expect(context.request.userId == testUserId)
            #expect(context.body.data == "context test")

            // Test that request can decode the body correctly
            let decodedBody = try request.decodedRequestBody(MockPostEndpoint.Body.self)
            #expect(decodedBody.data == "context test")
        }

        @Test("Async stream endpoint integration")
        func asyncStreamEndpointIntegration() async throws {
            let route = MockRoute()

            let configuredRoute = route.stream(MockStreamEndpoint.self) { context in
                AsyncStream<MockStreamEndpoint.Chunk> { continuation in
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk1"))
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk2"))
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk3"))
                    continuation.finish()
                }
            }

            #expect(configuredRoute.path == "/mock/stream")
            #expect(configuredRoute.method == EndpointMethod.POST)

            // Test that the handler is properly configured
            let request = MockRequest()
            let response = try await configuredRoute.handler(request)
            #expect(response.data != nil)
        }
    }
}
