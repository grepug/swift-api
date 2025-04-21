//
//  Client.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import ErrorKit
import Foundation
import SwiftAPICore

public protocol APIClientKind {
    func data<E: Endpoint>(on endpoint: E) async throws(APIClientError) -> E.ResponseContent
    func stream<E: Endpoint, S: AsyncSequence>(on endpoint: E) -> S where S.Element == E.ResponseChunk
    func data<T: Decodable>(_ path: String, method: EndpointMethod, decodingAs type: T.Type) async throws(APIClientError) -> T

    func accessToken() -> String
    func makeStream<S>(request: URLRequest) -> S where S: AsyncSequence

    var baseURL: URL { get }
}

public enum APIClientError: Throwable, Catching {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(message: String)
    case invalidAccessToken
    case caught(_ error: Error)

    public var userFriendlyMessage: String {
        switch self {
        case .invalidResponse:
            "Invalid response from server."
        case .invalidAccessToken:
            "Invalid access token."
        case .serverError(let statusCode, let message):
            "Server error with status code: \(statusCode), message: \(message)"
        case .decodingError(let message):
            "Failed to decode response: \(message)"
        case .caught(let error):
            ErrorKit.userFriendlyMessage(for: error)
        }
    }
}

extension APIClientKind {
    func urlRequest(path: String, method: EndpointMethod) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(component: path))

        request.httpMethod = method.rawValue
        request.addValue("Content-Type", forHTTPHeaderField: "application/json")
        request.addValue("Accept", forHTTPHeaderField: "application/json")
        request.addValue("Authorization", forHTTPHeaderField: "Bearer \(accessToken())")

        return request
    }

    public func data<E>(on endpoint: E) async throws(APIClientError) -> E.ResponseContent where E: Endpoint {
        try await data(E.path, method: E.method, decodingAs: E.ResponseContent.self)
    }

    public func stream<E, S>(on endpoint: E) -> S where E: Endpoint, S: AsyncSequence, E.ResponseChunk == S.Element {
        let stream: S = makeStream(request: urlRequest(path: E.path, method: E.method))
        return stream
    }

    public func data<T>(_ path: String, method: EndpointMethod, decodingAs type: T.Type) async throws(APIClientError) -> T where T: Decodable {
        let data: Data

        do {
            let request = urlRequest(path: path, method: method)
            let (_data, response) = try await URLSession.shared.throwableData(for: request)

            data = _data

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIClientError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
        } catch {
            throw APIClientError.caught(error)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIClientError.decodingError(message: ErrorKit.errorChainDescription(for: error))
        }
    }
}
