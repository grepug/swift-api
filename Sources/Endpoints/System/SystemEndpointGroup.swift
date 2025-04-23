import SwiftAPICore

public protocol SystemEndpointGroupProtocol: EndpointGroup {
    associatedtype Route: RouteKind

    typealias E1 = EP.System.AppConfig
    func fetchAppConfig(request: Route.Request, EndpointType: E1.Type) async throws -> E1.ResponseContent
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

        public struct AppConfig: Endpoint {
            public var query: RequestQuery

            static public var path: String { "/system/app-config" }
            static public var method: EndpointMethod { .GET }

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
