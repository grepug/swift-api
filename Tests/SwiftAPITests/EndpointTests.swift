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

        @Test("EmptyCodable method overload resolution")
        func emptyCodableMethodOverloadResolution() throws {
            // Test that EmptyCodable-specific methods are called instead of generic ones
            // We'll use invalid JSON data to differentiate the behavior:
            // - Generic method would try to decode and throw an error
            // - EmptyCodable-specific method always returns EmptyCodable() regardless of data

            let invalidJsonData = "invalid json".data(using: .utf8)!
            let requestWithInvalidData = MockRequest(
                bodyData: invalidJsonData,
                queryData: invalidJsonData
            )

            // If the generic CoSendable method were called, it would try to decode the invalid JSON
            // and throw an error. If the EmptyCodable-specific method is called, it should
            // return EmptyCodable() without attempting to decode.

            // This should call the EmptyCodable-specific overload and NOT throw
            let decodedBody = try requestWithInvalidData.decodedRequestBody(EmptyCodable.self)
            #expect(decodedBody == EmptyCodable())

            // This should call the EmptyCodable-specific overload and NOT throw
            let decodedQuery = try requestWithInvalidData.decodedRequestQuery(EmptyCodable.self)
            #expect(decodedQuery == EmptyCodable())

            // For comparison, let's verify that the generic method WOULD throw with invalid JSON
            // by testing with a different CoSendable type
            struct TestType: CoSendable {
                let value: String
            }

            // This should use the generic method and throw because of invalid JSON
            #expect(throws: (any Error).self) {
                _ = try requestWithInvalidData.decodedRequestBody(TestType.self)
            }

            #expect(throws: (any Error).self) {
                _ = try requestWithInvalidData.decodedRequestQuery(TestType.self)
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
