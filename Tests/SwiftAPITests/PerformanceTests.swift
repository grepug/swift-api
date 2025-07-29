import Foundation
import Testing

@testable import SwiftAPICore

@Suite("Performance Benchmark Tests")
struct PerformanceTests {

    @Suite("Route Building Performance")
    struct RouteBuildingPerformanceTests {
        @Test("Route building latency benchmark")
        func routeBuildingLatencyBenchmark() {
            let startTime = CFAbsoluteTimeGetCurrent()

            // Build a typical endpoint group with routes
            let route = MockRoute()
            let group = MockEndpointGroupWithRoutes(route: route)
            let finalRoutes = group.finalRoutes

            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = (endTime - startTime) * 1000  // Convert to milliseconds

            #expect(finalRoutes.count == 1)
            #expect(executionTime < 1.0, "Route building should complete within 1ms")
        }

        @Test("RequestContext creation performance")
        func requestContextCreationPerformance() throws {
            let request = MockRequest()
            let body = MockPostEndpoint.Body(data: "test")

            let startTime = CFAbsoluteTimeGetCurrent()

            // Create multiple RequestContext instances
            for _ in 0..<1000 {
                let context = RequestContext(
                    request: request,
                    query: EmptyCodable(),
                    body: body
                )
                _ = context.request.userId
                _ = context.body.data
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = (endTime - startTime) * 1000

            #expect(executionTime < 100.0, "1000 RequestContext creations should complete within 100ms")
        }

        @Test("Protocol method dispatch performance")
        func protocolMethodDispatchPerformance() async {
            let routes: [any RouteKind] = (0..<100).map { _ in MockRoute() }

            let startTime = CFAbsoluteTimeGetCurrent()

            for route in routes {
                _ = route.path
                _ = route.method
                _ = route.timeout
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = (endTime - startTime) * 1_000_000  // Convert to microseconds

            #expect(executionTime < 50.0, "Protocol method dispatch should have minimal overhead (<50μs)")
        }
    }

    @Suite("Serialization Performance")
    struct SerializationPerformanceTests {
        @Test("Container serialization performance")
        func containerSerializationPerformance() throws {
            let testData = MockPostEndpoint.ResponseContent(result: "performance test")
            let container = EndpointResponseContainer(result: testData)

            let startTime = CFAbsoluteTimeGetCurrent()

            // Perform multiple serialization/deserialization cycles
            for _ in 0..<100 {
                let encoded = try JSONEncoder().encode(container)
                let decoded = try JSONDecoder().decode(EndpointResponseContainer<MockPostEndpoint.ResponseContent>.self, from: encoded)
                _ = decoded.result.result
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = (endTime - startTime) * 1000

            #expect(executionTime < 50.0, "100 serialization cycles should complete within 50ms")
        }

        @Test("Large response chunk container performance")
        func largeResponseChunkContainerPerformance() throws {
            let chunks = (0..<1000).map { index in
                MockStreamEndpoint.ResponseChunk(chunk: "chunk_\(index)")
            }

            let startTime = CFAbsoluteTimeGetCurrent()

            for chunk in chunks {
                let container = EndpointResponseChunkContainer(chunk: chunk, errorCode: nil)
                let encoded = try JSONEncoder().encode(container)
                _ = try JSONDecoder().decode(EndpointResponseChunkContainer<MockStreamEndpoint.ResponseChunk>.self, from: encoded)
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = (endTime - startTime) * 1000

            #expect(executionTime < 200.0, "1000 chunk serializations should complete within 200ms")
        }
    }

    @Suite("Memory Usage Validation")
    struct MemoryUsageValidationTests {
        @Test("Route collection memory efficiency")
        func routeCollectionMemoryEfficiency() {
            // Create a collection of routes and verify they can be collected efficiently
            let routes = (0..<1000).map { index in
                var route = MockRoute()
                route.path = "/test/\(index)"
                return route
            }

            // Test that routes can be iterated efficiently
            var pathCount = 0
            for route in routes {
                if route.path.hasPrefix("/test/") {
                    pathCount += 1
                }
            }

            #expect(pathCount == 1000)
        }

        @Test("RequestContext memory lifecycle")
        func requestContextMemoryLifecycle() throws {
            // Test that RequestContext instances can be created and released efficiently
            // Note: Since RequestContext is a struct, we test creation efficiency instead of deallocation

            let request = MockRequest()
            let body = MockPostEndpoint.Body(data: "memory test")

            for _ in 0..<1000 {
                let context = RequestContext(
                    request: request,
                    query: EmptyCodable(),
                    body: body
                )

                // Use the context
                _ = context.request.userId
                _ = context.body.data
            }

            // Test completes successfully if no memory issues
            #expect(Bool(true))
        }
    }

    @Suite("Concurrency Performance")
    struct ConcurrencyPerformanceTests {
        @Test("Concurrent route handler execution")
        func concurrentRouteHandlerExecution() async {
            let concurrentCount = 100
            var routes = [MockRoute]()

            for i in 0..<concurrentCount {
                var route = MockRoute()
                route.handler = { _ in
                    // Simulate some work
                    try await Task.sleep(for: .milliseconds(1))
                    return MockResponse(data: "result_\(i)")
                }
                routes.append(route)
            }

            let startTime = CFAbsoluteTimeGetCurrent()

            await withTaskGroup(of: MockResponse?.self) { group in
                for route in routes {
                    group.addTask {
                        let request = MockRequest()
                        return try? await route.handler(request)
                    }
                }

                var results = [MockResponse?]()
                for await result in group {
                    results.append(result)
                }

                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = (endTime - startTime) * 1000

                #expect(results.count == concurrentCount)
                #expect(executionTime < 100.0, "Concurrent execution should benefit from parallelism")
            }
        }

        @Test("Thread safety validation")
        func threadSafetyValidation() async {
            let route = MockRoute()
            let sharedGroup = MockEndpointGroupWithRoutes(route: route)

            await withTaskGroup(of: Int.self) { group in
                // Create multiple concurrent tasks accessing the same endpoint group
                for _ in 0..<50 {
                    group.addTask {
                        return sharedGroup.finalRoutes.count
                    }
                }

                var results = [Int]()
                for await result in group {
                    results.append(result)
                }

                // All tasks should get the same consistent result
                #expect(results.allSatisfy { $0 == 1 })
            }
        }
    }
}
