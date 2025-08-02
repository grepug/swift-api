import Foundation
import Testing

@testable import SwiftAPICore

@Suite("RouteBuilder Result Builder Tests")
struct RouteBuilderTests {

    @Suite("Builder Functionality")
    struct BuilderFunctionalityTests {
        @Test("Empty routes array building")
        func emptyRoutesArrayBuilding() {
            let routes = RouteBuilder.buildBlock()
            #expect(routes.isEmpty)
        }

        @Test("Single route building")
        func singleRouteBuilding() {
            let mockRoute = MockRoute()
            let routes = RouteBuilder.buildBlock(mockRoute)
            #expect(routes.count == 1)
        }

        @Test("Multiple routes building")
        func multipleRoutesBuilding() {
            let route1 = MockRoute()
            let route2 = MockRoute()
            let routes = RouteBuilder.buildBlock(route1, route2)
            #expect(routes.count == 2)
        }

        @Test("Optional route building")
        func optionalRouteBuilding() {
            let mockRoute: [any RouteKind]? = [MockRoute()]
            let routes = RouteBuilder.buildOptional(mockRoute)
            #expect(routes.count == 1)

            let nilRoutes = RouteBuilder.buildOptional(nil)
            #expect(nilRoutes.isEmpty)
        }

        @Test("Nested array flattening")
        func nestedArrayFlattening() {
            let array1 = [MockRoute()]
            let array2 = [MockRoute(), MockRoute()]
            let routes = RouteBuilder.buildBlock(array1, array2)
            #expect(routes.count == 3)
        }
    }

    @Suite("Routes Type Alias")
    struct RoutesTypeAliasTests {
        @Test("Routes type compatibility")
        func routesTypeCompatibility() {
            let mockRoutes: Routes = [MockRoute()]
            let arrayRoutes: [any RouteKind] = [MockRoute()]

            // Verify they can be used interchangeably
            func acceptRoutes(_ routes: Routes) -> Int { routes.count }
            func acceptArray(_ routes: [any RouteKind]) -> Int { routes.count }

            #expect(acceptRoutes(mockRoutes) == 1)
            #expect(acceptArray(arrayRoutes) == 1)
        }
    }
}
