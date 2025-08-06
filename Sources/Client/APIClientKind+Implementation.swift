import ErrorKit
import Foundation
import SwiftAPICore

// MARK: - APIClientKind Default Implementation

extension APIClientKind {

    // MARK: - URL Request Building

    /// Creates a URL request for the given parameters
    ///
    /// - Parameters:
    ///   - path: The API path
    ///   - method: The HTTP method
    ///   - query: The query parameters
    ///   - body: The request body data
    /// - Returns: A configured URLRequest
    func urlRequest(
        path: String,
        method: EndpointMethod,
        query: [URLQueryItem],
        body: Data,
    ) -> URLRequest {
        let pathComponent = path.split(separator: "/", omittingEmptySubsequences: true)

        var url = baseURL

        for component in pathComponent {
            url.appendPathComponent(String(component))
        }

        url.append(queryItems: query)

        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        request.addValue("Bearer \(accessToken())", forHTTPHeaderField: "Authorization")

        if method.hasBody {
            request.httpBody = body
        }

        return request
    }

    // MARK: - Endpoint Data Request

    /// Performs a data request on the specified endpoint
    ///
    /// This is the main method for making endpoint requests with automatic
    /// encoding of query parameters and request body.
    ///
    /// - Parameter endpoint: The endpoint to make the request to
    /// - Returns: The decoded response content
    /// - Throws: APIClientError for various failure scenarios
    public func data<E>(on endpoint: E) async throws(APIClientError) -> E.Content where E: Endpoint {
        try await data(
            E.path,
            method: E.method,
            query: endpoint.query,
            body: endpoint.body,
            decodingAs: E.Content.self,
        )
    }

    // MARK: - Streaming Request

    /// Creates a streaming connection to the specified endpoint
    ///
    /// This method handles streaming responses by creating an async stream
    /// that yields response chunks as they arrive from the server.
    ///
    /// - Parameter endpoint: The endpoint to stream from
    /// - Returns: An async throwing stream of response chunks
    public func stream<E>(on endpoint: E) -> AsyncThrowingStream<E.Chunk, Error> where E: Endpoint {
        let body = try! JSONEncoder().encode(endpoint.body)
        let query = makeQuery(endpoint.query)
        let request = urlRequest(
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
                    continuation.finish(throwing: APIClientError.serverError(statusCode: container.errorCode!, message: ""))
                    return
                }

                continuation.yield(container.chunk)
            }
        }
    }

    // MARK: - Generic Data Request

    /// Performs a generic data request with custom parameters
    ///
    /// This method provides flexibility for making custom API requests with
    /// any combination of query parameters and request body.
    ///
    /// - Parameters:
    ///   - path: The API path
    ///   - method: The HTTP method
    ///   - query: The query parameters
    ///   - body: The request body
    ///   - type: The type to decode the response as
    /// - Returns: The decoded response of the specified type
    /// - Throws: APIClientError for various failure scenarios
    public func data<T, Body, Query>(
        _ path: String,
        method: EndpointMethod,
        query: Query,
        body: Body,
        decodingAs type: T.Type,
    ) async throws(APIClientError) -> T where T: Codable, Body: Encodable, Query: Encodable {
        let data: Data

        do {
            let body = try! JSONEncoder().encode(body)
            let query = makeQuery(query)
            let request = urlRequest(
                path: path,
                method: method,
                query: query,
                body: body,
            )
            let (_data, response) = try await URLSession.shared.throwableData(for: request)

            data = _data

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse
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
                    throw APIClientError.handledByErrorHandler
                } else {
                    // If not handled, throw a server error with the status code and message
                    throw APIClientError.serverError(statusCode: statusCode, message: message)
                }
            }
        } catch is CancellationError {
            throw .cancelled
        } catch let error as APIClientError {
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
            throw APIClientError.decodingError(message: ErrorKit.errorChainDescription(for: error))
        }
    }

    // MARK: - Private Utilities

    /// Converts an encodable object to URL query items
    ///
    /// - Parameter codable: The encodable object to convert
    /// - Returns: Array of URL query items
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
