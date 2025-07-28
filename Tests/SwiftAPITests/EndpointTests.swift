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
