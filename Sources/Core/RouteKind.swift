//
//  RouteKind.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import Foundation

public protocol RouteKind: Sendable {
    associatedtype Request: RouteRequestKind
    associatedtype Response: RouteResponseKind

    var path: String { get set }
    var method: EndpointMethod { get set }
    var timeout: TimeInterval { get }

    var handler: (Request) async throws -> Response { get set }

    init()
}

extension RouteKind {
    public var timeout: TimeInterval {
        60
    }

    public func block<E>(_ endpoint: E.Type, handler: @escaping @Sendable (_ req: Request, _ E: E.Type) async throws -> E.ResponseContent) -> Self where E: Endpoint, E.ResponseChunk == EmptyCodable {
        var me = self
        me.path = endpoint.path
        me.method = endpoint.method

        me.handler = { req in
            let result = try await handler(req, endpoint)
            return Response.fromCodable(result)
        }

        return me
    }

    public func stream<E, S>(_ endpoint: E.Type, handler: @escaping @Sendable (_ req: Request, _ E: E.Type) async throws -> S) -> Self
    where E: Endpoint, S: AsyncSequence, E.ResponseChunk == S.Element {
        var me = self
        me.path = endpoint.path
        me.method = endpoint.method

        me.handler = { req in
            let result = try await handler(req, endpoint)
            return Response.fromStream(result)
        }

        return me
    }
}

public protocol RouteRequestKind {
    var userId: UUID { get throws }

    func decodedRequestBody<T: CoSendable>(_ type: T.Type) throws -> T
    func decodedRequestQuery<T: CoSendable>(_ type: T.Type) throws -> T
}

public protocol RouteResponseKind {
    static func fromCodable<T>(_ codable: T) -> Self where T: CoSendable
    static func fromStream<S: AsyncSequence>(_ stream: S) -> Self where S.Element: CoSendable

    init()
}
