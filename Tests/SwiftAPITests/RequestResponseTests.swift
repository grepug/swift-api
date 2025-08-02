import Foundation
import Testing

@testable import SwiftAPICore

@Suite("Request/Response Protocol Tests")
struct RequestResponseTests {

    @Suite("RouteRequestKind Implementation")
    struct RouteRequestKindTests {
        @Test("User ID access")
        func userIdAccess() throws {
            let testUserId = UUID()
            let request = MockRequest(userId: testUserId)
            #expect(request.userId == testUserId)
        }

        @Test("Request body decoding with valid data")
        func requestBodyDecodingWithValidData() throws {
            let originalBody = MockPostEndpoint.Body(data: "test content")
            let bodyData = try JSONEncoder().encode(originalBody)
            let request = MockRequest(bodyData: bodyData)

            let decodedBody = try request.decodedRequestBody(MockPostEndpoint.Body.self)
            #expect(decodedBody.data == "test content")
        }

        @Test("Request body decoding with empty data")
        func requestBodyDecodingWithEmptyData() throws {
            let request = MockRequest()
            let emptyBody = try request.decodedRequestBody(EmptyCodable.self)
            #expect(emptyBody == EmptyCodable())
        }

        @Test("Request query decoding with valid data")
        func requestQueryDecodingWithValidData() throws {
            struct TestQuery: CoSendable {
                let search: String
            }

            let originalQuery = TestQuery(search: "test")
            let queryData = try JSONEncoder().encode(originalQuery)
            let request = MockRequest(queryData: queryData)

            let decodedQuery = try request.decodedRequestQuery(TestQuery.self)
            #expect(decodedQuery.search == "test")
        }

        @Test("Request query decoding with empty data")
        func requestQueryDecodingWithEmptyData() throws {
            let request = MockRequest()
            let emptyQuery = try request.decodedRequestQuery(EmptyCodable.self)
            #expect(emptyQuery == EmptyCodable())
        }
    }

    @Suite("RouteResponseKind Implementation")
    struct RouteResponseKindTests {
        @Test("Codable response creation")
        func codableResponseCreation() {
            let testData = MockPostEndpoint.Content(result: "success")
            let response = MockResponse.fromCodable(testData)

            if let responseData = response.data as? MockPostEndpoint.Content {
                #expect(responseData.result == "success")
            } else {
                #expect(Bool(false), "Response data should be MockPostEndpoint.Content")
            }
        }

        @Test("Stream response creation")
        func streamResponseCreation() async {
            let stream = AsyncStream<MockStreamEndpoint.Chunk> { continuation in
                continuation.yield(MockStreamEndpoint.Chunk(chunk: "test"))
                continuation.finish()
            }

            let response = MockResponse.fromStream(stream)
            #expect(response.data != nil)
        }

        @Test("Response initialization")
        func responseInitialization() {
            let response = MockResponse()
            #expect(response.data == nil)

            let responseWithData = MockResponse(data: "test")
            if let data = responseWithData.data as? String {
                #expect(data == "test")
            } else {
                #expect(Bool(false), "Response data should be String")
            }
        }
    }
}
