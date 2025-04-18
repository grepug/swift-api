public protocol RouteGroup: Sendable {
    @RouteBuilder
    var routes: Routes { get }

    var path: String { get }
}
