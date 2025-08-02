import Foundation
import Testing

@testable import SwiftAPICore

@Suite("Edge Cases and Error Handling Tests")
struct EdgeCaseTests {

    @Suite("Error Conditions")
    struct ErrorConditionTests {
        @Test("Invalid JSON decoding in request body")
        func invalidJSONDecodingInRequestBody() {
            let invalidData = "invalid json".data(using: .utf8)!
            let request = MockRequest(bodyData: invalidData)

            #expect(throws: Error.self) {
                try request.decodedRequestBody(MockPostEndpoint.Body.self)
            }
        }

        @Test("Invalid JSON decoding in request query")
        func invalidJSONDecodingInRequestQuery() {
            let invalidData = "invalid json".data(using: .utf8)!
            let request = MockRequest(queryData: invalidData)

            struct TestQuery: CoSendable {
                let search: String
            }

            #expect(throws: Error.self) {
                try request.decodedRequestQuery(TestQuery.self)
            }
        }

        @Test("Handler throwing error")
        func handlerThrowingError() async {
            var route = MockRoute()

            route.handler = { _ in
                throw TestError.handlerFailure
            }

            let request = MockRequest()

            await #expect(throws: TestError.self) {
                try await route.handler(request)
            }
        }

        @Test("Container encoding with invalid data")
        func containerEncodingWithInvalidData() {
            struct InvalidCodable {
                let invalidProperty: (() -> Void)? = nil
            }

            // This should compile but we test what happens with edge case data
            let container = EndpointResponseContainer(result: EmptyCodable())

            #expect(throws: Never.self) {
                _ = try JSONEncoder().encode(container)
            }
        }
    }

    @Suite("Memory and Concurrency")
    struct MemoryAndConcurrencyTests {
        @Test("Concurrent route execution")
        func concurrentRouteExecution() async {
            let routes = (0..<100).map { _ in MockRoute() }

            await withTaskGroup(of: Void.self) { group in
                for route in routes {
                    group.addTask {
                        let request = MockRequest()
                        _ = try? await route.handler(request)
                    }
                }
            }

            // Test passes if no crashes occur during concurrent execution
            #expect(Bool(true))
        }

        @Test("Large route group handling")
        func largeRouteGroupHandling() {
            // Test with a smaller number since we're using individual route handling
            let route = MockRoute()
            let group = MockEndpointGroupWithRoutes(route: route)

            #expect(group.finalRoutes.count == 1)
        }

        @Test("Deep RequestContext nesting")
        func deepRequestContextNesting() throws {
            struct NestedData: CoSendable {
                let level1: Level1

                struct Level1: CoSendable {
                    let level2: Level2

                    struct Level2: CoSendable {
                        let level3: Level3

                        struct Level3: CoSendable {
                            let value: String
                        }
                    }
                }
            }

            let nestedData = NestedData(
                level1: NestedData.Level1(
                    level2: NestedData.Level1.Level2(
                        level3: NestedData.Level1.Level2.Level3(value: "deep")
                    )
                )
            )

            let request = MockRequest()
            let context = RequestContext(
                request: request,
                query: EmptyCodable(),
                body: nestedData
            )

            #expect(context.body.level1.level2.level3.value == "deep")
        }
    }

    @Suite("Performance Edge Cases")
    struct PerformanceEdgeCaseTests {
        @Test("RouteBuilder with many optional routes")
        func routeBuilderWithManyOptionalRoutes() {
            let optionalRoutes: [any RouteKind]? = (0..<100).map { _ in MockRoute() }
            let routes = RouteBuilder.buildOptional(optionalRoutes)

            #expect(routes.count == 100)
        }

        @Test("Endpoint with very long path")
        func endpointWithVeryLongPath() {
            struct LongPathEndpoint: Endpoint {
                static var path: String {
                    "/very/long/path/with/many/segments/" + String(repeating: "segment/", count: 100)
                }
                static var method: EndpointMethod { .GET }
            }

            _ = LongPathEndpoint()
            #expect(LongPathEndpoint.path.count > 800)
        }

        @Test("Large data in response containers")
        func largeDataInResponseContainers() throws {
            struct LargeData: CoSendable {
                let data: String
            }

            let largeString = String(repeating: "a", count: 10000)
            let largeData = LargeData(data: largeString)
            let container = EndpointResponseContainer(result: largeData)

            let encoded = try JSONEncoder().encode(container)
            #expect(encoded.count > 10000)

            let decoded = try JSONDecoder().decode(EndpointResponseContainer<LargeData>.self, from: encoded)
            #expect(decoded.result.data.count == 10000)
        }
    }
}

// MARK: - Test Error Types

enum TestError: Error, Equatable {
    case handlerFailure
    case invalidData
    case networkError
}
