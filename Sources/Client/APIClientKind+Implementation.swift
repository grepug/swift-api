import ErrorKit
import Foundation
import SwiftAPICore

// MARK: - APIClientKind Default Implementation

/// Default implementation of APIClientKind providing common functionality
/// for making HTTP requests to API endpoints with automatic encoding/decoding.
extension APIClientKind {

    // MARK: - URL Request Building

    /// Creates a URL request for the given parameters
    ///
    /// This method constructs a complete URLRequest by:
    /// - Building the full URL from base URL and path components
    /// - Adding query parameters to the URL
    /// - Setting the HTTP method and authorization header
    /// - Adding request body for POST/PUT methods
    ///
    /// - Parameters:
    ///   - path: The API path (e.g., "/users/123" or "users/profile")
    ///   - method: The HTTP method (GET, POST, PUT, DELETE)
    ///   - query: The query parameters as URLQueryItem array
    ///   - body: The request body data (ignored for GET/DELETE)
    /// - Returns: A configured URLRequest ready for execution
    func urlRequest(
        path: String,
        method: EndpointMethod,
        query: [URLQueryItem],
        body: Data,
    ) async -> URLRequest {
        let pathComponent = path.split(separator: "/", omittingEmptySubsequences: true)

        var url = baseURL

        for component in pathComponent {
            url.appendPathComponent(String(component))
        }

        url.append(queryItems: query)

        var request = URLRequest(url: url)

        let accessToken = await accessToken()

        request.httpMethod = method.rawValue
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if method.hasBody {
            request.httpBody = body
        }

        return request
    }

    // MARK: - Endpoint Data Request

    /// Performs a data request on the specified endpoint with simplified error handling
    ///
    /// This method is designed for endpoints that use `EmptyError` as their error type,
    /// providing a simpler interface without custom error handling. It automatically:
    /// - Encodes the endpoint's query parameters and request body
    /// - Makes the HTTP request using the endpoint's configuration
    /// - Decodes the response into the endpoint's Content type
    /// - Handles standard HTTP errors and API client errors
    ///
    /// - Parameter endpoint: The endpoint to make the request to
    /// - Returns: The decoded response content of type `E.Content`
    /// - Throws: `APIClientError<E.Error>` for various failure scenarios including:
    ///   - Network connectivity issues
    ///   - HTTP status code errors (4xx, 5xx)
    ///   - JSON encoding/decoding failures
    ///   - Request cancellation
    public func data<E>(on endpoint: E) async throws(APIClientError<E.Error>) -> E.Content where E: Endpoint {
        try await data(
            E.path,
            method: E.method,
            query: endpoint.query,
            body: endpoint.body,
            errorType: E.Error.self,
            decodingAs: E.Content.self,
        )
    }

    /// Performs a data request on the specified endpoint with custom error handling
    ///
    /// This method provides the same functionality as the basic `data(on:)` method but
    /// includes a custom error handler that gets called when endpoint-specific errors occur.
    /// The error handler receives the decoded endpoint error for custom processing.
    ///
    /// **Usage Example:**
    /// ```swift
    /// let result = try await client.data(on: userEndpoint) { error in
    ///     // Handle specific user endpoint errors
    ///     print("User error occurred: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to make the request to
    ///   - errorHandler: A closure called when endpoint-specific errors occur
    /// - Returns: The decoded response content of type `E.Content`
    /// - Throws: `APIClientError<E.Error>` after error handler execution
    // public func data<E>(on endpoint: E, errorHandler: (E.Error) -> Void) async throws(APIClientError<E.Error>) -> E.Content where E: Endpoint {
    //     do {
    //         return try await data(
    //             E.path,
    //             method: E.method,
    //             query: endpoint.query,
    //             body: endpoint.body,
    //             errorType: E.Error.self,
    //             decodingAs: E.Content.self,
    //         )
    //     } catch {
    //         if case .endpointError(let endpointError) = error {
    //             errorHandler(endpointError)
    //         }

    //         throw error
    //     }
    // }

    // MARK: - Streaming Request

    /// Creates a streaming connection to the specified endpoint
    ///
    /// This method handles Server-Sent Events (SSE) or streaming responses by creating
    /// an async stream that yields response chunks as they arrive from the server.
    /// Each chunk is automatically decoded from JSON and validated for errors.
    ///
    /// The stream will:
    /// - Encode the endpoint's body and query parameters
    /// - Establish a streaming connection to the server
    /// - Decode each chunk as `EndpointResponseChunkContainer<E.Chunk>`
    /// - Check for error codes and terminate the stream if errors occur
    /// - Yield successfully decoded chunks to the caller
    ///
    /// **Usage Example:**
    /// ```swift
    /// for try await chunk in client.stream(on: chatEndpoint) {
    ///     print("Received chunk: \(chunk)")
    /// }
    /// ```
    ///
    /// - Parameter endpoint: The endpoint to stream from
    /// - Returns: An async throwing stream that yields `E.Chunk` objects
    /// - Throws: Various errors including network issues, decoding failures, or server errors
    public func stream<E>(on endpoint: E) async -> AsyncThrowingStream<E.Chunk, Error> where E: Endpoint {
        let body = try! JSONEncoder().encode(endpoint.body)
        let query = makeQuery(endpoint.query)
        let request = await urlRequest(
            path: E.path,
            method: E.method,
            query: query,
            body: body,
        )
        let stream = makeStream(request: request)

        return .makeCancellable { continuation in
            for try await string in stream {
                let data = string.data(using: .utf8) ?? Data()
                let container = try JSONDecoder().decode(EndpointResponseChunkContainer<E.Chunk>.self, from: data)

                guard container.errorCode == nil else {
                    continuation.finish(throwing: APIClientError<E.Error>.serverError(statusCode: container.errorCode!, message: ""))
                    return
                }

                continuation.yield(container.chunk)
            }
        }
    }

    // MARK: - Generic Data Request

    /// Performs a generic data request with custom parameters and comprehensive error handling
    ///
    /// This is the most flexible method for making API requests, allowing complete customization
    /// of all request parameters. It handles the full request lifecycle including:
    /// - JSON encoding of query parameters and request body
    /// - HTTP request execution with proper error handling
    /// - Response validation and status code checking
    /// - Automatic error type detection and custom error handler integration
    /// - JSON decoding of successful responses
    ///
    /// **Error Handling Flow:**
    /// 1. Network and URL session errors are caught and wrapped
    /// 2. HTTP status codes outside 200-299 trigger error handling
    /// 3. Server error handler is called for potential custom handling
    /// 4. Endpoint-specific errors are decoded if possible
    /// 5. Generic server errors are created for unhandled cases
    ///
    /// **Usage Example:**
    /// ```swift
    /// let user = try await client.data(
    ///     "/users/profile",
    ///     method: .GET,
    ///     query: UserQuery(includeDetails: true),
    ///     body: EmptyCodable(),
    ///     errorType: UserError.self,
    ///     decodingAs: User.self
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - path: The API path (e.g., "/users/123", "admin/settings")
    ///   - method: The HTTP method to use for the request
    ///   - query: The query parameters object (must be Encodable)
    ///   - body: The request body object (must be Encodable)
    ///   - errorType: The type for decoding endpoint-specific errors
    ///   - type: The expected response type for successful requests
    /// - Returns: The decoded response of the specified type
    /// - Throws: `APIClientError<Error>` with specific error cases:
    ///   - `.cancelled`: Request was cancelled
    ///   - `.invalidResponse`: Invalid HTTP response
    ///   - `.serverError`: HTTP error with status code and message
    ///   - `.endpointError`: Decoded endpoint-specific error
    ///   - `.urlSessionError`: Network connectivity issues
    ///   - `.decodingError`: JSON decoding failures
    ///   - `.caught`: Unexpected errors
    ///   - `.handledByErrorHandler`: Error was processed by custom handler
    public func data<T, Body, Query, Error>(
        _ path: String,
        method: EndpointMethod,
        query: Query,
        body: Body,
        errorType: Error.Type,
        decodingAs type: T.Type,
    ) async throws(APIClientError<Error>) -> T where T: Codable, Body: Encodable, Query: Encodable, Error: CodableError {
        typealias ClientError = APIClientError<Error>

        let data: Data

        do {
            let body = try! JSONEncoder().encode(body)
            let query = makeQuery(query)
            let request = await urlRequest(
                path: path,
                method: method,
                query: query,
                body: body,
            )
            let (_data, response) = try await URLSession.shared.throwableData(for: request)

            data = _data

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.invalidResponse
            }

            let statusCode = httpResponse.statusCode

            guard (200...299).contains(statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"

                // Attempt to handle the error with the error handler
                let handled = await handleServerResponseError(
                    statusCode: statusCode,
                    message: message,
                    response: httpResponse
                )

                if handled {
                    // If handled, throw a specific error to indicate it was processed
                    throw ClientError.handledByErrorHandler
                } else if let decodedError = try? JSONDecoder().decode(Error.self, from: data) {
                    throw ClientError.endpointError(decodedError)
                } else {
                    // If not handled, throw a server error with the status code and message
                    throw ClientError.serverError(statusCode: statusCode, message: message)
                }
            }
        } catch is CancellationError {
            throw .cancelled
        } catch let error as ClientError {
            throw error
        } catch {
            if let error = error as? URLSessionError {
                throw .urlSessionError(error)
            }

            throw .caught(error)
        }

        do {
            let container = try JSONDecoder().decode(EndpointResponseContainer<T>.self, from: data)
            return container.result
        } catch {
            assertionFailure("Failed to decode response: \(error)")
            throw ClientError.decodingError(message: ErrorKit.errorChainDescription(for: error))
        }
    }

    // MARK: - Private Utilities

    /// Converts an encodable object to URL query items
    ///
    /// This method provides flexible query parameter conversion supporting:
    /// - Direct `[String: String]` dictionaries
    /// - Any `Encodable` object using reflection via `Mirror`
    /// - Automatic string conversion of property values
    ///
    /// **Note:** For complex objects, consider using a dedicated query encoder
    /// for more sophisticated parameter handling (nested objects, arrays, etc.).
    ///
    /// **Usage Example:**
    /// ```swift
    /// struct SearchQuery: Encodable {
    ///     let term: String
    ///     let limit: Int
    /// }
    /// let query = SearchQuery(term: "swift", limit: 10)
    /// let queryItems = makeQuery(query)
    /// // Results in: [URLQueryItem(name: "term", value: "swift"), URLQueryItem(name: "limit", value: "10")]
    /// ```
    ///
    /// - Parameter codable: The encodable object to convert to query parameters
    /// - Returns: Array of URLQueryItem objects suitable for URL construction
    private func makeQuery<T: Encodable>(_ codable: T) -> [URLQueryItem] {
        var params = [String: String]()

        if let dict = codable as? [String: String] {
            params = dict
        } else {
            let mirror = Mirror(reflecting: codable)
            for child in mirror.children {
                if let key = child.label {
                    params[key] = "\(child.value)"
                }
            }
        }

        return params.map {
            .init(name: $0.key, value: $0.value)
        }
    }
}
