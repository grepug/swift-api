public protocol EndpointGroupProtocol: Sendable {
    @RouteBuilder
    var routes: Routes { get }

    @RouteBuilder
    var additionalRoutes: Routes { get }
}

extension EndpointGroupProtocol {
    public var finalRoutes: Routes {
        routes + additionalRoutes
    }

    @RouteBuilder
    public var additionalRoutes: Routes {}
}
