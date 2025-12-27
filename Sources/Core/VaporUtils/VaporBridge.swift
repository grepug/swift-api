#if Server
    import Vapor
    import VaporUtils

    public struct APIRoute: RouteKind {
        public typealias Request = Vapor.Request
        public typealias Response = Vapor.Response

        public var method: EndpointMethod = .GET
        public var path: String = ""
        public var handler: (@Sendable (Vapor.Request) async throws -> Vapor.Response) = { _ in fatalError() }

        public init(_ path: String = "", _ method: EndpointMethod = .GET, handler: @escaping @Sendable (Vapor.Request) async throws -> Vapor.Response = { _ in fatalError() }) {
            self.path = path
            self.method = method
            self.handler = { req in
                try await injectRequestDependencies(request: req) {
                    try await handler(req)
                }
            }
        }

        public init() {
            self.init("", .GET)
        }
    }

    struct APIError<Payload>: AbortError, ResponseEncodable where Payload: Sendable & Codable {
        let status: HTTPResponseStatus
        let reason: String
        let payload: Payload

        func encodeResponse(for request: Vapor.Request) -> NIOCore.EventLoopFuture<Vapor.Response> {
            do {
                let response = Response(status: status, headers: headers)

                // Ensure JSON if caller didn't override
                if response.headers.contentType == nil {
                    response.headers.contentType = .json
                }

                let data = try JSONEncoder().encode(payload)

                response.body = .init(data: data)

                return request.eventLoop.makeSucceededFuture(response)
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
        }
    }

    struct ResponseEncodableErrorMiddleware: Middleware {
        func respond(to req: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
            next.respond(to: req).flatMapError { error in
                if let encodable = error as? ResponseEncodable {
                    return encodable.encodeResponse(for: req)
                }
                // Hand off to the next middleware in the chain
                return req.eventLoop.makeFailedFuture(error)
            }
        }
    }

    extension Response: RouteResponseKind {
        public static func fromCodable<T>(_ codable: T) -> Self where T: Codable, T: Hashable, T: Sendable {
            .codable2(codable)
        }

        public static func fromStream<S>(_ stream: S) -> Self where S: AsyncSequence, S: Sendable, S.Element: Codable, S.Element: Sendable, S.Element: Hashable {
            // FIXME: temporarily using a timeout of 300 seconds
            .codableStream(stream, timeout: 300)
        }

        public static func mapError<T>(_ payload: T) -> Error where T: Codable, T: Sendable {
            APIError(status: .badRequest, reason: "bad request", payload: payload)
        }

        public convenience init() {
            self.init(status: .ok)
        }
    }

    extension Request: RouteRequestKind {
        public var userId: UUID {
            get throws {
                if application.environment == .testing {
                    for header in headers {
                        if header.name == "Testing-User-Id" {
                            return UUID(uuidString: header.value)!
                        }
                    }
                }

                guard let id = payload?.userId else {
                    throw Abort(.unauthorized, reason: "Missing userId")
                }

                return id
            }
        }

        public func decodedRequestBody<T>(_ type: T.Type) throws -> T where T: Decodable, T: Encodable, T: Sendable {
            if let bodyData = body.data {
                let data = Data(buffer: bodyData)
                return try JSONDecoder().decode(T.self, from: data)
            }

            assertionFailure("No body data in request")

            throw Abort(.badRequest, reason: "No body data")
        }

        public func decodedRequestQuery<T>(_ type: T.Type) throws -> T where T: Decodable, T: Encodable, T: Sendable {
            let query = try query.decode(T.self)
            return query
        }

        public func injectedDependency<T>(_ handler: @escaping () async throws -> T) async rethrows -> T where T: Sendable {
            try await injectRequestDependencies(request: self) {
                try await handler()
            }
        }
    }

    extension SwiftAPICore.EndpointMethod {
        var httpMethod: HTTPMethod {
            switch self {
            case .DELETE: .DELETE
            case .GET: .GET
            case .POST: .POST
            case .PUT: .PUT
            }
        }
    }

    public protocol EndpointGroupController: RouteCollection, EndpointGroupProtocol where Self.Route == APIRoute {}

    extension EndpointGroupController {
        public func boot(routes: any RoutesBuilder) throws {
            for route in self.finalRoutes {
                guard let route = route as? APIRoute else {
                    continue
                }

                let pathComponents = route.path.split(separator: "/", omittingEmptySubsequences: true)

                routes.on(
                    route.method.httpMethod,
                    pathComponents.map { PathComponent(stringLiteral: String($0)) },
                    use: route.handler
                )
            }
        }
    }

#endif
