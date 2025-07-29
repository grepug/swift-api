import Foundation
import Testing

@testable import SwiftAPICore

@Suite("Endpoint Protocol Tests")
struct EndpointTests {

    @Suite("Runtime Behavior")
    struct RuntimeBehaviorTests {
        @Test("Endpoint instantiation and property access")
        func endpointInstantiationAndPropertyAccess() {
            _ = MockGetEndpoint()
            #expect(MockGetEndpoint.path == "/mock/get")
            #expect(MockGetEndpoint.method == EndpointMethod.GET)

            let postEndpoint = MockPostEndpoint(body: .init(data: "test"))
            #expect(postEndpoint.body.data == "test")
            #expect(MockPostEndpoint.path == "/mock/post")
            #expect(MockPostEndpoint.method == EndpointMethod.POST)
        }

        @Test(
            "EndpointMethod hasBody behavior",
            arguments: [
                (EndpointMethod.GET, false),
                (EndpointMethod.POST, true),
                (EndpointMethod.PUT, true),
                (EndpointMethod.DELETE, false),
            ])
        func endpointMethodHasBody(method: EndpointMethod, expectedHasBody: Bool) {
            #expect(method.hasBody == expectedHasBody)
        }

        @Test("EmptyCodable serialization")
        func emptyCodableSerializationTests() throws {
            let empty = EmptyCodable()
            let encoded = try JSONEncoder().encode(empty)
            let decoded = try JSONDecoder().decode(EmptyCodable.self, from: encoded)
            #expect(decoded == empty)
        }

        @Test("EmptyCodable runtime type checking")
        func emptyCodableRuntimeTypeChecking() async throws {
            // Test that the runtime type checking in RouteKind.block() correctly handles EmptyCodable
            // The logic: E.Query.self is EmptyCodable.Type ? EmptyCodable() as! E.Query : try req.decodedRequestQuery(E.Query.self)

            // Create a mock route to test the block method
            let mockRoute = MockRoute()

            // Test with an endpoint that has EmptyCodable for Query and Body
            struct EmptyEndpoint: Endpoint {
                static var path: String { "/empty" }
                static var method: EndpointMethod { .GET }

                typealias Query = EmptyCodable
                typealias Body = EmptyCodable
                typealias ResponseContent = MockPostEndpoint.ResponseContent
                typealias ResponseChunk = EmptyCodable

                var body: Body { EmptyCodable() }
                var query: Query { EmptyCodable() }
            }

            // Configure the route with the empty endpoint
            let configuredRoute = mockRoute.block(EmptyEndpoint.self) { context in
                // This handler should receive EmptyCodable instances for query and body
                // without any JSON decoding attempts
                #expect(context.query == EmptyCodable())
                #expect(context.body == EmptyCodable())
                return MockPostEndpoint.ResponseContent(result: "success")
            }

            // Create a request with invalid JSON data
            let invalidJsonData = "invalid json".data(using: .utf8)!
            let requestWithInvalidData = MockRequest(
                bodyData: invalidJsonData,
                queryData: invalidJsonData
            )

            // The handler should work without throwing, because EmptyCodable types
            // are handled by runtime type checking, not JSON decoding
            let response = try await configuredRoute.handler(requestWithInvalidData)

            // Verify the response was created successfully
            let mockResponse = response as MockResponse
            if let responseData = mockResponse.data as? MockPostEndpoint.ResponseContent {
                #expect(responseData.result == "success")
            } else {
                #expect(Bool(false), "Response should contain MockPostEndpoint.ResponseContent")
            }
        }

        @Test("EmptyCodable vs CoSendable type checking")
        func emptyCodableVsCoSendableTypeChecking() async throws {
            // Test that non-EmptyCodable types still use JSON decoding
            struct NonEmptyEndpoint: Endpoint {
                static var path: String { "/non-empty" }
                static var method: EndpointMethod { .POST }

                typealias Query = MockPostEndpoint.Body  // CoSendable but not EmptyCodable
                typealias Body = MockPostEndpoint.Body  // CoSendable but not EmptyCodable
                typealias ResponseContent = MockPostEndpoint.ResponseContent
                typealias ResponseChunk = EmptyCodable

                var body: Body { MockPostEndpoint.Body(data: "default") }
                var query: Query { MockPostEndpoint.Body(data: "default") }
            }

            let mockRoute = MockRoute()
            let configuredRoute = mockRoute.block(NonEmptyEndpoint.self) { context in
                return MockPostEndpoint.ResponseContent(result: "success")
            }

            // With invalid JSON, this should throw because non-EmptyCodable types
            // go through the JSON decoding path
            let invalidJsonData = "invalid json".data(using: .utf8)!
            let requestWithInvalidData = MockRequest(
                bodyData: invalidJsonData,
                queryData: invalidJsonData
            )

            await #expect(throws: (any Error).self) {
                _ = try await configuredRoute.handler(requestWithInvalidData)
            }
        }
    }

    @Suite("Container Types")
    struct ContainerTypeTests {
        @Test("EndpointResponseContainer functionality")
        func endpointResponseContainerFunctionality() throws {
            let testData = MockPostEndpoint.ResponseContent(result: "success")
            let container = EndpointResponseContainer(result: testData)

            let encoded = try JSONEncoder().encode(container)
            let decoded = try JSONDecoder().decode(EndpointResponseContainer<MockPostEndpoint.ResponseContent>.self, from: encoded)

            #expect(decoded.result.result == "success")
        }

        @Test("EndpointResponseChunkContainer with error codes", arguments: [nil, 400, 500])
        func endpointResponseChunkContainerWithErrorCodes(errorCode: Int?) throws {
            let chunk = MockStreamEndpoint.ResponseChunk(chunk: "data")
            let container = EndpointResponseChunkContainer(chunk: chunk, errorCode: errorCode)

            let encoded = try JSONEncoder().encode(container)
            let decoded = try JSONDecoder().decode(EndpointResponseChunkContainer<MockStreamEndpoint.ResponseChunk>.self, from: encoded)

            #expect(decoded.chunk.chunk == "data")
            #expect(decoded.errorCode == errorCode)
        }
    }
}
