import SwiftAPICore

public protocol SystemEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.System.AppConfig
    typealias E2 = EP.System.SetRedis
    typealias E3 = EP.System.RedisFetch

    func fetchAppConfig(context: Context<E1>) async throws -> E1.Content
    func setRedis(context: Context<E2>) async throws -> E2.Content
    func fetchRedis(context: Context<E3>) async throws -> E3.Content
}

extension SystemEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, fetchAppConfig)
        Route().block(E2.self, setRedis)
        Route().block(E3.self, fetchRedis)
    }
}

extension EP {
    @EndpointGroup("system")
    public enum System {}
}

extension EP.System {
    @Endpoint("app-config", .GET)
    public struct AppConfig {
        public var query: Query

        @DTO
        public struct Query {
            public var appBuild: String
        }

        @DTO
        public struct Content {
            public var forceUpdate: Bool
            public var appReviewMode: Bool
            public var isAppReviewing: Bool
        }
    }

    @Endpoint("set-redis", .POST)
    public struct SetRedis {
        public var body: Body

        @DTO
        public struct Body {
            public var key: String
            public var value: String
        }
    }

    @Endpoint("fetch-redis", .POST)
    public struct RedisFetch {
        public var body: Body

        @DTO
        public struct Body {
            public var key: String
        }

        @DTO
        public struct Content {
            public var value: String?
        }
    }
}
