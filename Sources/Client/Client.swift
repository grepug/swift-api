//
//  Client.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import Foundation
import SwiftAPICore

public protocol APIClientKind {
    func data<E: Endpoint>(on endpoint: E) async throws -> E.ResponseContent
    func stream<E: Endpoint, S: AsyncSequence>(on endpoint: E) async throws -> S where S.Element == E.ResponseChunk
    func data<T: Decodable>(_ path: String, method: EndpointMethod, decodingAs type: T.Type) async throws -> T

    func accessToken() throws -> String
    func makeStream<S>(request: URLRequest) -> S where S: AsyncSequence

    var baseURL: URL { get }
}

public enum APIClientError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(message: String)
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

extension APIClientKind {
    func urlRequest<E: Endpoint>(endpoint: E) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appending(component: E.finalPath))

        request.httpMethod = E.method.rawValue
        request.addValue("Content-Type", forHTTPHeaderField: "application/json")
        request.addValue("Accept", forHTTPHeaderField: "application/json")
        request.addValue("Authorization", forHTTPHeaderField: "Bearer \(try accessToken())")

        return request
    }

    public func data<E>(on endpoint: E) async throws -> E.ResponseContent where E: Endpoint {
        let request = try urlRequest(endpoint: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(E.ResponseContent.self, from: data)
        } catch {
            throw APIClientError.decodingError(message: error.localizedDescription)
        }
    }

    public func stream<E, S>(on endpoint: E) async throws -> S where E: Endpoint, S: AsyncSequence, E.ResponseChunk == S.Element {
        let stream: S = makeStream(request: try urlRequest(endpoint: endpoint))
        return stream
    }

    public func data<T>(_ path: String, method: EndpointMethod, decodingAs type: T.Type) async throws -> T where T: Decodable {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.addValue("Content-Type", forHTTPHeaderField: "application/json")
        request.addValue("Accept", forHTTPHeaderField: "application/json")
        request.addValue("Authorization", forHTTPHeaderField: "Bearer \(try accessToken())")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIClientError.decodingError(message: error.localizedDescription)
        }
    }
}
