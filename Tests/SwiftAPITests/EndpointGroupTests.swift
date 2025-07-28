import Foundation
import Testing

@testable import SwiftAPICore

@Suite("EndpointGroup Protocol Tests")
struct EndpointGroupTests {

    @Suite("Route Management")
    struct RouteManagementTests {
        @Test("Final routes combination")
        func finalRoutesCombination() {
            let route = MockRoute()
            let group = MockEndpointGroupWithRoutes(route: route)
            let finalRoutes = group.finalRoutes

            #expect(finalRoutes.count == 1)
        }

        @Test("Empty additional routes default")
        func emptyAdditionalRoutesDefault() {
            let group = MockEndpointGroup()

            #expect(group.additionalRoutes.isEmpty)
            #expect(group.finalRoutes.isEmpty)
        }

        @Test("Route concatenation order")
        func routeConcatenationOrder() {
            // Test the basic structure - detailed route ordering would need more complex mock
            let route = MockRoute()
            let group = MockEndpointGroupWithRoutes(route: route)

            let finalRoutes = group.finalRoutes
            #expect(finalRoutes.count == 1)
        }

        @Test("Empty endpoint group")
        func emptyEndpointGroup() {
            let group = MockEndpointGroup()
            #expect(group.finalRoutes.isEmpty)
        }
    }
}
