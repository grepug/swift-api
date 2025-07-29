import SwiftAPICore

public protocol SystemEndpointGroupProtocol: EndpointGroup {
    associatedtype Route: RouteKind

    typealias E1 = EP.System.AppConfig
    func fetchAppConfig(
        context: RequestContext<Route.Request, E1.RequestQuery, E1.RequestBody>
    ) async throws -> E1.ResponseContent
}

extension SystemEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route()
            .block(EP.System.AppConfig.self, handler: fetchAppConfig)
    }
}

extension EP {
    public enum System {

        @Endpoint("/system/app-config", .GET)
        public struct AppConfig {
            public var query: RequestQuery

            public init(query: RequestQuery) {
                self.query = query
            }
        }
    }
}

extension EP.System.AppConfig {
    public struct RequestQuery: CoSendable {
        public var appBuild: String

        public init(appBuild: String) {
            self.appBuild = appBuild
        }
    }

    public struct ResponseContent: CoSendable {
        public var forceUpdate: Bool
        public var appReviewMode: Bool

        public init(forceUpdate: Bool, appReviewMode: Bool) {
            self.forceUpdate = forceUpdate
            self.appReviewMode = appReviewMode
        }
    }
}
