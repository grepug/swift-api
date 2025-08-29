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

public struct RequestContext<Request: RouteRequestKind, Query: Sendable, Body: Sendable>: Sendable {
    public let request: Request
    public let query: Query
    public let body: Body
}

extension RouteKind {
    public var timeout: TimeInterval {
        60
    }

    public func block<E>(
        _ endpoint: E.Type,
        _ handler: @escaping @Sendable (_ context: RequestContext<Request, E.Query, E.Body>) async throws -> E.Content
    ) -> Self where E: Endpoint, E.Chunk == EmptyCodable, E.Error == EmptyError {
        var me = self
        me.path = E.path
        me.method = E.method

        me.handler = { req in
            let query = E.Query.self is EmptyCodable.Type ? EmptyCodable() as! E.Query : try req.decodedRequestQuery(E.Query.self)
            let body = E.Body.self is EmptyCodable.Type ? EmptyCodable() as! E.Body : try req.decodedRequestBody(E.Body.self)

            let context = RequestContext(
                request: req,
                query: query,
                body: body,
            )

            let result = try await req.injectedDependency {
                try await handler(context)
            }

            return Response.fromCodable(result)
        }

        return me
    }

    public func block<E>(
        _ endpoint: E.Type,
        _ handler: @escaping @Sendable (_ context: RequestContext<Request, E.Query, E.Body>) async throws(E.Error) -> E.Content
    ) -> Self where E: Endpoint, E.Chunk == EmptyCodable {
        var me = self
        me.path = E.path
        me.method = E.method

        me.handler = { req in
            let query = E.Query.self is EmptyCodable.Type ? EmptyCodable() as! E.Query : try req.decodedRequestQuery(E.Query.self)
            let body = E.Body.self is EmptyCodable.Type ? EmptyCodable() as! E.Body : try req.decodedRequestBody(E.Body.self)

            let context = RequestContext(
                request: req,
                query: query,
                body: body,
            )

            let result = try await req.injectedDependency {
                do {
                    return try await handler(context)
                } catch let error as E.Error {
                    throw Response.mapError(error)
                }
            }

            return Response.fromCodable(result)
        }

        return me
    }

    public func stream<E, S>(
        _ endpoint: E.Type,
        _ handler: @escaping @Sendable (_ context: RequestContext<Request, E.Query, E.Body>) async throws -> S
    ) -> Self where E: Endpoint, S: AsyncSequence, E.Chunk == S.Element, S: Sendable {
        var me = self
        me.path = E.path
        me.method = E.method

        me.handler = { req in
            let query = E.Query.self is EmptyCodable.Type ? EmptyCodable() as! E.Query : try req.decodedRequestQuery(E.Query.self)
            let body = E.Body.self is EmptyCodable.Type ? EmptyCodable() as! E.Body : try req.decodedRequestBody(E.Body.self)

            let context = RequestContext(
                request: req,
                query: query,
                body: body
            )

            let result = try await req.injectedDependency {
                try await handler(context)
            }

            return Response.fromStream(result)
        }

        return me
    }
}

public protocol RouteRequestKind: Sendable {
    var userId: UUID { get throws }

    func decodedRequestBody<T: CoSendable>(_ type: T.Type) throws -> T
    func decodedRequestQuery<T: CoSendable>(_ type: T.Type) throws -> T

    func injectedDependency<T>(_ handler: @escaping () async throws -> T) async rethrows -> T where T: Sendable
}

public protocol RouteResponseKind {
    static func fromCodable<T>(_ codable: T) -> Self where T: CoSendable
    static func fromStream<S: AsyncSequence>(_ stream: S) -> Self where S.Element: CoSendable
    static func mapError<T>(_ payload: T) -> Error where T: Codable, T: Sendable

    init()
}
