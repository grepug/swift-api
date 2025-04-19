public protocol EndpointGroup: Sendable {
    @RouteBuilder
    var routes: Routes { get }

    @RouteBuilder
    var additionalRoutes: Routes { get }

    var groupedPath: String { get }
}

extension EndpointGroup {
    public var finalRoutes: Routes {
        routes + additionalRoutes
    }

    @RouteBuilder
    public var additionalRoutes: Routes {}
}
