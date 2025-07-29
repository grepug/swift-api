//
//  Endpoint.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import Foundation

public enum EndpointMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case DELETE

    public var hasBody: Bool {
        switch self {
        case .POST, .PUT: true
        default: false
        }
    }
}

public typealias CoSendable = Sendable & Codable & Hashable

public struct EmptyCodable: CoSendable {
    public init() {}
}

public protocol Endpoint: Sendable {
    associatedtype RequestBody: CoSendable = EmptyCodable
    associatedtype RequestQuery: CoSendable = EmptyCodable
    associatedtype ResponseChunk: CoSendable = EmptyCodable
    associatedtype ResponseContent: CoSendable = EmptyCodable

    static var path: String { get }
    static var method: EndpointMethod { get }

    var body: RequestBody { get }
    var query: RequestQuery { get }
}

extension Endpoint where RequestBody == EmptyCodable {
    public var body: RequestBody { EmptyCodable() }
}

extension Endpoint where RequestQuery == EmptyCodable {
    public var query: RequestQuery { EmptyCodable() }
}

extension Endpoint where ResponseChunk == EmptyCodable {
    public var response: ResponseChunk { EmptyCodable() }
}

extension Endpoint where ResponseContent == EmptyCodable {
    public var response: ResponseContent { EmptyCodable() }
}

public struct EndpointResponseContainer<T: Codable>: Codable {
    public var result: T

    public init(result: T) {
        self.result = result
    }
}

public struct EndpointResponseChunkContainer<T: Codable>: Codable {
    public var chunk: T
    public var errorCode: Int?

    public init(chunk: T, errorCode: Int? = nil) {
        self.chunk = chunk
        self.errorCode = errorCode
    }
}
