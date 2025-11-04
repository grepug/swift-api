import SwiftAPICore

public protocol SystemEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.System.AppConfig
    typealias E2 = EP.System.SetRedis
    typealias E3 = EP.System.RedisFetch
    typealias E4 = EP.System.SuggestedFulltexts

    func fetchAppConfig(context: Context<E1>) async throws -> E1.Content
    func setRedis(context: Context<E2>) async throws -> E2.Content
    func fetchRedis(context: Context<E3>) async throws -> E3.Content
    func fetchSuggestedFulltexts(context: Context<E4>) async throws -> E4.Content
}

extension SystemEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, fetchAppConfig)
        Route().block(E2.self, setRedis)
        Route().block(E3.self, fetchRedis)
        Route().block(E4.self, fetchSuggestedFulltexts)
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

    @Endpoint("suggested-fulltexts", .GET)
    public struct SuggestedFulltexts {

        @DTO
        public struct Content {
            @DTO
            public struct Item {
                public let title: String
                public let filePath: String
                public let coverImagePath: String?
                public let author: String?
                public let source: String?
                public let description: String?
            }

            public var items: [Item]
        }
    }
}
