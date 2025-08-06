import SwiftAPICore

public protocol SystemEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.System.AppConfig

    func fetchAppConfig(context: Context<E1>) async throws -> E1.Content
}

extension SystemEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, fetchAppConfig)
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
}
