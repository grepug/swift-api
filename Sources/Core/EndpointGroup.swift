/// Protocol for endpoint group naming
public protocol EndpointGroup {
    /// The name of the endpoint group
    static var name: String { get }
}

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
