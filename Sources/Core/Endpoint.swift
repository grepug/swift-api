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

public protocol CodableError: Error, CoSendable {}

public struct EmptyError: CodableError {}

public protocol Endpoint: Sendable {
    associatedtype Body: CoSendable = EmptyCodable
    associatedtype Query: CoSendable = EmptyCodable
    associatedtype Chunk: CoSendable = EmptyCodable
    associatedtype Content: CoSendable = EmptyCodable
    associatedtype Error: CodableError = EmptyError

    static var path: String { get }
    static var method: EndpointMethod { get }

    var body: Body { get }
    var query: Query { get }
}

extension Endpoint where Body == EmptyCodable {
    public var body: Body { EmptyCodable() }
}

extension Endpoint where Query == EmptyCodable {
    public var query: Query { EmptyCodable() }
}

extension Endpoint where Chunk == EmptyCodable {
    public var response: Chunk { EmptyCodable() }
}

extension Endpoint where Content == EmptyCodable {
    public var response: Content { EmptyCodable() }
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
