/// Protocol for endpoint group naming
public protocol EndpointGroup {
    /// The name of the endpoint group
    static var name: String { get }
}

public protocol EndpointGroupProtocol: Sendable {
    associatedtype Route: RouteKind

    typealias Context<E: Endpoint> = RequestContext<Route.Request, E.Query, E.Body>
    /// The type of route handled by this endpoint group
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
