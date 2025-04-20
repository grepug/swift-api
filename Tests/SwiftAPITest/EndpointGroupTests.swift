import Foundation
import Testing

@testable import ContextEndpoints
@testable import SwiftAPICore

// MARK: - Mock Route Implementation

/// Mock RouteKind implementation for testing
struct MockRoute: RouteKind {
    struct MockRequest: RouteRequestKind {
        var userId: UUID {
            get throws {
                UUID()
            }
        }

        func decodedRequestBody<T: CoSendable>(_ type: T.Type) throws -> T {
            fatalError("Not implemented for test")
        }

        func decodedRequestQuery<T: CoSendable>(_ type: T.Type) throws -> T {
            fatalError("Not implemented for test")
        }
    }

    struct MockResponse: RouteResponseKind {
        static func fromCodable<T>(_ codable: T) -> MockResponse where T: CoSendable {
            return MockResponse()
        }

        static func fromStream<S: AsyncSequence>(_ stream: S) -> MockResponse where S.Element: CoSendable {
            return MockResponse()
        }

        init() {}
    }

    var path: String = ""
    var method: EndpointMethod = .GET
    var handler: @Sendable (MockRequest) async throws -> MockResponse = { _ in return MockResponse() }

    init() {}
}

// MARK: - Mock EndpointGroup Implementation

/// A simple mock implementation of EndpointGroup for testing
struct MockEndpointGroup: EndpointGroup {
    let groupedPath: String
    let routes: Routes
    let additionalRoutes: Routes

    init(groupedPath: String = "/test", routes: Routes = [], additionalRoutes: Routes = []) {
        self.groupedPath = groupedPath
        self.routes = routes
        self.additionalRoutes = additionalRoutes
    }

    // Create a helper to build routes with specific paths
    static func createRoutesWithPaths(_ paths: [String]) -> Routes {
        return paths.map { path in
            var route = MockRoute()
            route.path = path
            return route
        }
    }
}

// MARK: - EndpointGroup Tests

@Test func testEndpointGroupCombinesRoutes() {
    // Arrange
    let mainRoutes = MockEndpointGroup.createRoutesWithPaths(["/one", "/two"])
    let additionalRoutes = MockEndpointGroup.createRoutesWithPaths(["/three", "/four"])

    let group = MockEndpointGroup(
        routes: mainRoutes,
        additionalRoutes: additionalRoutes
    )

    // Act
    let combinedRoutes = group.finalRoutes

    // Assert
    // Test that all routes are included
    #expect(combinedRoutes.count == 4)

    // Test route paths
    let paths = combinedRoutes.map { $0.path }
    #expect(paths.contains("/one"))
    #expect(paths.contains("/two"))
    #expect(paths.contains("/three"))
    #expect(paths.contains("/four"))
}

@Test func testEndpointGroupWithEmptyAdditionalRoutes() {
    // Arrange
    let mainRoutes = MockEndpointGroup.createRoutesWithPaths(["/one", "/two"])

    let group = MockEndpointGroup(
        routes: mainRoutes,
        additionalRoutes: []
    )

    // Act
    let combinedRoutes = group.finalRoutes

    // Assert
    #expect(combinedRoutes.count == 2)

    let paths = combinedRoutes.map { $0.path }
    #expect(paths.contains("/one"))
    #expect(paths.contains("/two"))
    #expect(!paths.contains("/three"))
}

@Test func testEndpointGroupWithEmptyRoutes() {
    // Arrange
    let additionalRoutes = MockEndpointGroup.createRoutesWithPaths(["/three", "/four"])

    let group = MockEndpointGroup(
        routes: [],
        additionalRoutes: additionalRoutes
    )

    // Act
    let combinedRoutes = group.finalRoutes

    // Assert
    #expect(combinedRoutes.count == 2)

    let paths = combinedRoutes.map { $0.path }
    #expect(!paths.contains("/one"))
    #expect(paths.contains("/three"))
    #expect(paths.contains("/four"))
}

@Test func testEndpointGroupWithNoRoutes() {
    // Arrange
    let group = MockEndpointGroup(
        routes: [],
        additionalRoutes: []
    )

    // Act
    let combinedRoutes = group.finalRoutes

    // Assert
    #expect(combinedRoutes.isEmpty)
}

@Test func testEndpointGroupPreservesRouteMethods() {
    // Arrange
    var getRoute = MockRoute()
    getRoute.method = .GET
    getRoute.path = "/get"

    var postRoute = MockRoute()
    postRoute.method = .POST
    postRoute.path = "/post"

    let group = MockEndpointGroup(
        groupedPath: "/methods",
        routes: [getRoute, postRoute]
    )

    // Act
    let routes = group.finalRoutes

    // Assert
    #expect(routes.count == 2)

    let getRoutes = routes.filter { $0.method == .GET }
    let postRoutes = routes.filter { $0.method == .POST }

    #expect(getRoutes.count == 1)
    #expect(postRoutes.count == 1)
    #expect(getRoutes.first?.path == "/get")
    #expect(postRoutes.first?.path == "/post")
}

@Test func testEndpointGroupGroupedPath() {
    // Arrange
    let customPath = "/custom/path"
    let group = MockEndpointGroup(
        groupedPath: customPath,
        routes: MockEndpointGroup.createRoutesWithPaths(["/one"]),
        additionalRoutes: MockEndpointGroup.createRoutesWithPaths(["/two"])
    )

    // Act & Assert
    #expect(group.groupedPath == customPath)
}
