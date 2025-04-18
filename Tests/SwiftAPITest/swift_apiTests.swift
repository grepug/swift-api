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

// MARK: - Test Helpers

/// Custom error type for test assertions
enum TestError: Error {
    case expectationFailed(String)
}
