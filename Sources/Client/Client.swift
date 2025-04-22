//
//  Client.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import ConcurrencyUtils
import ErrorKit
import Foundation
import SwiftAPICore

public protocol APIClientKind {
    func data<E: Endpoint>(on endpoint: E) async throws(APIClientError) -> E.ResponseContent
    func stream<E>(on endpoint: E) -> AsyncThrowingStream<E.ResponseChunk, Error> where E: Endpoint
    func data<T, Body, Query>(_ path: String, method: EndpointMethod, query: Query, body: Body, decodingAs type: T.Type) async throws(APIClientError) -> T
    where T: Decodable, Body: Encodable, Query: Encodable

    func accessToken() -> String
    func makeStream(request: URLRequest) -> AsyncThrowingStream<String, Error>

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
    func urlRequest(path: String, method: EndpointMethod, query: [URLQueryItem], body: Data) -> URLRequest {
        let url =
            baseURL
            .appendingPathComponent("user")
            .appendingPathComponent(path)
            .appending(queryItems: query)

        var request = URLRequest(url: url)

        print("Creating request for URL: \(url)")

        request.httpMethod = method.rawValue
        request.addValue("Bearer \(accessToken())", forHTTPHeaderField: "Authorization")

        if method.hasBody {
            request.httpBody = body
        }

        return request
    }

    public func data<E>(on endpoint: E) async throws(APIClientError) -> E.ResponseContent where E: Endpoint {
        try await data(E.path, method: E.method, query: endpoint.query, body: endpoint.body, decodingAs: E.ResponseContent.self)
    }

    public func stream<E>(on endpoint: E) -> AsyncThrowingStream<E.ResponseChunk, Error> where E: Endpoint {
        let body = try! JSONEncoder().encode(endpoint.body)
        let query = makeQuery(endpoint.query)
        let request = urlRequest(path: E.path, method: E.method, query: query, body: body)
        let stream = makeStream(request: request)

        return .makeCancellable { continuation in
            for try await string in stream {
                let data = string.data(using: .utf8) ?? Data()
                let chunk = try JSONDecoder().decode(E.ResponseChunk.self, from: data)
                continuation.yield(chunk)
            }
        }
    }

    public func data<T, Body, Query>(_ path: String, method: EndpointMethod, query: Query, body: Body, decodingAs type: T.Type) async throws(APIClientError) -> T
    where T: Decodable, Body: Encodable, Query: Encodable {
        let data: Data

        do {
            let body = try! JSONEncoder().encode(body)
            let query = makeQuery(query)
            let request = urlRequest(path: path, method: method, query: query, body: body)
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
