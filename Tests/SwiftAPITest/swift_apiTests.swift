import Foundation
import Testing

@testable import SwiftAPIClient
@testable import SwiftAPICore
@testable import SwiftAPIEndpoints

// MARK: - Mock Client for Testing

/// A mock client that conforms to APIClientKind for testing endpoints
final class MockAPIClient {
    var baseURL: URL = URL(string: "https://api.example.com")!
    var shouldSucceed: Bool = true
    var mockResponse: Any?
    var capturedEndpoint: Any?
    var capturedRequest: URLRequest?

    func accessToken() -> String {
        return "mock-token"
    }
}

extension MockAPIClient: APIClientKind {
    func makeStream<S>(request: URLRequest) -> S where S: AsyncSequence {
        fatalError("Streaming not implemented in mock")
    }

    func data<E>(on endpoint: E) async throws -> E.ResponseContent where E: Endpoint {
        self.capturedEndpoint = endpoint

        if !shouldSucceed {
            throw APIClientError.serverError(statusCode: 500)
        }

        guard let response = mockResponse as? E.ResponseContent else {
            throw APIClientError.decodingError(message: "Mock response type mismatch")
        }

        return response
    }

    func stream<E, S>(on endpoint: E) async throws -> S where E: Endpoint, S: AsyncSequence, E.ResponseChunk == S.Element {
        fatalError("Streaming not implemented in mock")
    }

    func data<T>(_ path: String, method: EndpointMethod, decodingAs type: T.Type) async throws -> T where T: Decodable {
        if !shouldSucceed {
            throw APIClientError.serverError(statusCode: 500)
        }

        guard let response = mockResponse as? T else {
            throw APIClientError.decodingError(message: "Mock response type mismatch")
        }

        return response
    }
}

// MARK: - Endpoint Tests

@Test func testFetchFreeFeature_Success() async throws {
    // Arrange
    let mockClient = MockAPIClient()
    let expectedResponse = EP.User.FetchFreeFeature.ResponseContent(isAvailable: true)
    mockClient.mockResponse = expectedResponse

    let endpoint = EP.User.FetchFreeFeature(
        query: .init(feature: .someFeature)
    )

    // Act
    let result = try await mockClient.data(on: endpoint)

    // Assert
    #expect(result.isAvailable == true)

    // Verify endpoint configuration
    #expect(EP.User.FetchFreeFeature.finalPath == "/user/check-feature-availability")
    #expect(EP.User.FetchFreeFeature.method == .GET)

    // Verify captured endpoint query
    if let capturedEndpoint = mockClient.capturedEndpoint as? EP.User.FetchFreeFeature {
        #expect(capturedEndpoint.query.feature == .someFeature)
    }
}

@Test func testFetchFreeFeature_Failure() async throws {
    // Arrange
    let mockClient = MockAPIClient()
    mockClient.shouldSucceed = false

    let endpoint = EP.User.FetchFreeFeature(
        query: .init(feature: .anotherFeature)
    )

    // Act & Assert
    do {
        _ = try await mockClient.data(on: endpoint)
        // Use XCTFail equivalent for Testing framework
        throw TestError.expectationFailed("Expected error was not thrown")
    } catch let error as TestError {
        // Rethrow test errors
        throw error
    } catch let error as APIClientError {
        if case .serverError(let statusCode) = error {
            #expect(statusCode == 500)
        } else {
            // Use XCTFail equivalent for Testing framework
            throw TestError.expectationFailed("Unexpected error type: \(error)")
        }
    }
}

@Test func testFetchFreeFeature_AllFeatures() async throws {
    // Test with each feature type
    let features: [EP.User.FetchFreeFeature.Feature] = [
        .someFeature,
        .anotherFeature,
        .yetAnotherFeature,
    ]

    for feature in features {
        // Arrange
        let mockClient = MockAPIClient()
        let expectedResponse = EP.User.FetchFreeFeature.ResponseContent(isAvailable: feature == .someFeature)
        mockClient.mockResponse = expectedResponse

        let endpoint = EP.User.FetchFreeFeature(
            query: .init(feature: feature)
        )

        // Act
        let result = try await mockClient.data(on: endpoint)

        // Assert
        #expect(result.isAvailable == (feature == .someFeature))

        // Verify captured endpoint
        if let capturedEndpoint = mockClient.capturedEndpoint as? EP.User.FetchFreeFeature {
            #expect(capturedEndpoint.query.feature == feature)
        }
    }
}

// MARK: - UserStreamEndpoint Tests

@Test func testUserStreamEndpoint_Configuration() {
    // Verify endpoint configuration
    #expect(EP.User.UserStreamEndpoint.finalPath == "/user/xxx")
    #expect(EP.User.UserStreamEndpoint.method == .GET)
}

@Test func testUserStreamEndpoint_Streaming() async throws {
    // Create a custom MockStreamingClient for testing stream endpoints
    final class MockStreamingClient: APIClientKind {
        var baseURL: URL = URL(string: "https://api.example.com")!
        var capturedEndpoint: Any?
        var expectedChunks: [EP.User.UserStreamEndpoint.ResponseChunk] = []

        func accessToken() -> String {
            return "mock-token"
        }

        func makeStream<S>(request: URLRequest) -> S where S: AsyncSequence {
            fatalError("Not implemented")
        }

        func data<E>(on endpoint: E) async throws -> E.ResponseContent where E: Endpoint {
            fatalError("Not testing data endpoint")
        }

        func data<T>(_ path: String, method: EndpointMethod, decodingAs type: T.Type) async throws -> T where T: Decodable {
            fatalError("Not implemented")
        }

        func stream<E, S>(on endpoint: E) async throws -> S where E: Endpoint, S: AsyncSequence, E.ResponseChunk == S.Element {
            capturedEndpoint = endpoint

            // Create a custom streaming sequence with our test chunks
            let mockSequence = MockStreamSequence(chunks: expectedChunks) as! S
            return mockSequence
        }

        // Custom mock stream sequence
        final class MockStreamSequence<Element>: AsyncSequence {
            let chunks: [Element]

            init(chunks: [Element]) {
                self.chunks = chunks
            }

            func makeAsyncIterator() -> AsyncIterator {
                return AsyncIterator(chunks: chunks)
            }

            struct AsyncIterator: AsyncIteratorProtocol {
                var chunks: [Element]
                var index = 0

                mutating func next() async -> Element? {
                    guard index < chunks.count else { return nil }
                    let chunk = chunks[index]
                    index += 1
                    return chunk
                }
            }
        }
    }

    // Arrange
    let mockClient = MockStreamingClient()
    let expectedChunks = [
        EP.User.UserStreamEndpoint.ResponseChunk(text: "Hello"),
        EP.User.UserStreamEndpoint.ResponseChunk(text: "World"),
        EP.User.UserStreamEndpoint.ResponseChunk(text: "!"),
    ]
    mockClient.expectedChunks = expectedChunks

    let endpoint = EP.User.UserStreamEndpoint()

    // Act
    let stream: MockStreamingClient.MockStreamSequence<EP.User.UserStreamEndpoint.ResponseChunk> = try await mockClient.stream(on: endpoint)

    // Assert
    var receivedChunks: [EP.User.UserStreamEndpoint.ResponseChunk] = []
    for await chunk in stream {
        receivedChunks.append(chunk)
    }

    // Verify we received the expected chunks
    #expect(receivedChunks.count == expectedChunks.count)
    for (i, (received, expected)) in zip(receivedChunks, expectedChunks).enumerated() {
        #expect(received.text == expected.text, "Chunk at index \(i) doesn't match: '\(received.text)' vs expected '\(expected.text)'")
    }

    // Verify correct endpoint was called
    #expect(mockClient.capturedEndpoint is EP.User.UserStreamEndpoint)
}

@Test func testUserStreamEndpoint_Error() async throws {
    // Create a custom MockStreamingClient that throws an error
    final class ErrorStreamingClient: APIClientKind {
        var baseURL: URL = URL(string: "https://api.example.com")!
        var capturedEndpoint: Any?

        // Need to define a MockStreamSequence for type annotations
        final class MockStreamSequence<Element>: AsyncSequence {
            typealias AsyncIterator = DummyIterator

            struct DummyIterator: AsyncIteratorProtocol {
                mutating func next() async -> Element? {
                    return nil
                }
            }

            func makeAsyncIterator() -> DummyIterator {
                return DummyIterator()
            }
        }

        func accessToken() -> String {
            return "mock-token"
        }

        func makeStream<S>(request: URLRequest) -> S where S: AsyncSequence {
            fatalError("Not implemented")
        }

        func data<E>(on endpoint: E) async throws -> E.ResponseContent where E: Endpoint {
            fatalError("Not testing data endpoint")
        }

        func data<T>(_ path: String, method: EndpointMethod, decodingAs type: T.Type) async throws -> T where T: Decodable {
            fatalError("Not implemented")
        }

        func stream<E, S>(on endpoint: E) async throws -> S where E: Endpoint, S: AsyncSequence, E.ResponseChunk == S.Element {
            capturedEndpoint = endpoint
            throw APIClientError.serverError(statusCode: 503)
        }
    }

    // Arrange
    let mockClient = ErrorStreamingClient()
    let endpoint = EP.User.UserStreamEndpoint()

    // Act & Assert
    do {
        let _: ErrorStreamingClient.MockStreamSequence<EP.User.UserStreamEndpoint.ResponseChunk> = try await mockClient.stream(on: endpoint)
        throw TestError.expectationFailed("Expected error was not thrown")
    } catch let error as TestError {
        // Rethrow test errors
        throw error
    } catch let error as APIClientError {
        if case .serverError(let statusCode) = error {
            #expect(statusCode == 503)
        } else {
            throw TestError.expectationFailed("Unexpected error type: \(error)")
        }
    }

    // Verify correct endpoint was called
    #expect(mockClient.capturedEndpoint is EP.User.UserStreamEndpoint)
}

// MARK: - Test Helpers

/// Custom error type for test assertions
enum TestError: Error {
    case expectationFailed(String)
}
