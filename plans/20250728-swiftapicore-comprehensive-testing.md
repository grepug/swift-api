# SwiftAPICore Comprehensive Testing Plan

## Executive Summary

This plan outlines a comprehensive testing strategy for the SwiftAPICore module using the Swift Testing framework. SwiftAPICore is the foundational layer of the SwiftAPI framework, providing core protocols, types, and infrastructure for type-safe API endpoint definitions and route building. The testing strategy focuses on protocol conformance, type safety, result builder functionality, and integration patterns across all five core components.

## Test Architecture

### Framework Usage

- **Primary Framework**: Swift Testing (no XCTest dependencies)
- **Testing Approach**: Protocol-driven testing with mock implementations
- **Coverage Focus**: Core abstractions, type safety, and framework contracts
- **Test Organization**: Hierarchical test suites mirroring module structure

### Testing Philosophy

- **White-box Testing**: Full access to internal implementations via `@testable import`
- **Contract Testing**: Verify protocol conformance and behavioral contracts
- **Type Safety Validation**: Ensure generic constraints and associated types work correctly
- **Integration Testing**: Test cross-component interactions within the Core module

## Test Suites Structure

### 1. Endpoint Protocol Suite (`EndpointTests`)

````swift
## Test Suites Structure

### Mock Types for Testing

```swift
// MARK: - Mock Endpoint Types

struct MockGetEndpoint: Endpoint {
    static var path: String { "/mock/get" }
    static var method: EndpointMethod { .GET }
}

struct MockPostEndpoint: Endpoint {
    var body: Body
    static var path: String { "/mock/post" }
    static var method: EndpointMethod { .POST }

    init(body: Body) {
        self.body = body
    }
}

extension MockPostEndpoint {
    struct Body: CoSendable {
        let data: String
        init(data: String) { self.data = data }
    }

    struct Content: CoSendable {
        let result: String
        init(result: String) { self.result = result }
    }
}

struct MockStreamEndpoint: Endpoint {
    static var path: String { "/mock/stream" }
    static var method: EndpointMethod { .POST }
}

extension MockStreamEndpoint {
    struct Chunk: CoSendable {
        let chunk: String
        init(chunk: String) { self.chunk = chunk }
    }
}

// MARK: - Mock Route Types

struct MockRoute: RouteKind {
    var path: String = ""
    var method: EndpointMethod = .GET
    var handler: (MockRequest) async throws -> MockResponse = { _ in MockResponse() }

    init() {}
}

struct MockRequest: RouteRequestKind {
    let testUserId: UUID
    let bodyData: Data?
    let queryData: Data?

    var userId: UUID { testUserId }

    func decodedRequestBody<T: CoSendable>(_ type: T.Type) throws -> T {
        guard let data = bodyData else {
            return EmptyCodable() as! T
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func decodedRequestQuery<T: CoSendable>(_ type: T.Type) throws -> T {
        guard let data = queryData else {
            return EmptyCodable() as! T
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    init(userId: UUID = UUID(), bodyData: Data? = nil, queryData: Data? = nil) {
        self.testUserId = userId
        self.bodyData = bodyData
        self.queryData = queryData
    }
}

struct MockResponse: RouteResponseKind {
    let data: Any?

    static func fromCodable<T>(_ codable: T) -> MockResponse where T: CoSendable {
        return MockResponse(data: codable)
    }

    static func fromStream<S: AsyncSequence>(_ stream: S) -> MockResponse where S.Element: CoSendable {
        return MockResponse(data: stream)
    }

    init(data: Any? = nil) {
        self.data = data
    }
}

// MARK: - Mock EndpointGroupProtocol

struct MockEndpointGroup: EndpointGroupProtocol {
    let testRoutes: [any RouteKind]
    let testAdditionalRoutes: [any RouteKind]

    var routes: Routes { testRoutes }
    var additionalRoutes: Routes { testAdditionalRoutes }

    init(routes: [any RouteKind] = [], additionalRoutes: [any RouteKind] = []) {
        self.testRoutes = routes
        self.testAdditionalRoutes = additionalRoutes
    }
}
````

### 1. Endpoint Protocol Suite (`EndpointTests`)

```swift
@Suite("Endpoint Protocol Tests")
struct EndpointTests {

    @Suite("Runtime Behavior")
    struct RuntimeBehaviorTests {
        @Test("Endpoint instantiation and property access")
        func endpointInstantiationAndPropertyAccess() {
            let getEndpoint = MockGetEndpoint()
            #expect(MockGetEndpoint.path == "/mock/get")
            #expect(MockGetEndpoint.method == .GET)

            let postEndpoint = MockPostEndpoint(body: .init(data: "test"))
            #expect(postEndpoint.body.data == "test")
            #expect(MockPostEndpoint.path == "/mock/post")
            #expect(MockPostEndpoint.method == .POST)
        }

        @Test("EndpointMethod hasBody behavior", arguments: [
            (.GET, false),
            (.POST, true),
            (.PUT, true),
            (.DELETE, false)
        ])
        func endpointMethodHasBody(method: EndpointMethod, expectedHasBody: Bool) {
            #expect(method.hasBody == expectedHasBody)
        }

        @Test("EmptyCodable serialization")
        func emptyCodableSerializationTests() throws {
            let empty = EmptyCodable()
            let encoded = try JSONEncoder().encode(empty)
            let decoded = try JSONDecoder().decode(EmptyCodable.self, from: encoded)
            #expect(decoded == empty)
        }
    }

    @Suite("Container Types")
    struct ContainerTypeTests {
        @Test("EndpointResponseContainer functionality")
        func endpointResponseContainerFunctionality() throws {
            let testData = MockPostEndpoint.Content(result: "success")
            let container = EndpointResponseContainer(result: testData)

            let encoded = try JSONEncoder().encode(container)
            let decoded = try JSONDecoder().decode(EndpointResponseContainer<MockPostEndpoint.Content>.self, from: encoded)

            #expect(decoded.result.result == "success")
        }

        @Test("EndpointResponseChunkContainer with error codes", arguments: [nil, 400, 500])
        func endpointResponseChunkContainerWithErrorCodes(errorCode: Int?) throws {
            let chunk = MockStreamEndpoint.Chunk(chunk: "data")
            let container = EndpointResponseChunkContainer(chunk: chunk, errorCode: errorCode)

            let encoded = try JSONEncoder().encode(container)
            let decoded = try JSONDecoder().decode(EndpointResponseChunkContainer<MockStreamEndpoint.Chunk>.self, from: encoded)

            #expect(decoded.chunk.chunk == "data")
            #expect(decoded.errorCode == errorCode)
        }
    }
}
```

### 2. Route Builder Suite (`RouteBuilderTests`)

```swift
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
```

### 3. Route Kind Suite (`RouteKindTests`)

````swift
@Suite("RouteKind Protocol Tests")
struct RouteKindTests {

    @Suite("Route Configuration")
    struct RouteConfigurationTests {
        @Test("Default timeout value")
        func defaultTimeoutValue() {
            let route = MockRoute()
            #expect(route.timeout == 60.0)
        }

        @Test("Block endpoint configuration")
        func blockEndpointConfiguration() async throws {
            var route = MockRoute()

            let configuredRoute = route.block(MockPostEndpoint.self) { context in
                #expect(context.request.userId != UUID())
                #expect(context.body.data == "test")
                return MockPostEndpoint.Content(result: "success")
            }

            #expect(configuredRoute.path == "/mock/post")
            #expect(configuredRoute.method == .POST)
        }

        @Test("Stream endpoint configuration")
        func streamEndpointConfiguration() async throws {
            var route = MockRoute()

            let configuredRoute = route.stream(MockStreamEndpoint.self) { context in
                AsyncStream<MockStreamEndpoint.Chunk> { continuation in
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk1"))
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk2"))
                    continuation.finish()
                }
            }

            #expect(configuredRoute.path == "/mock/stream")
            #expect(configuredRoute.method == .POST)
        }

        @Test("RequestContext creation and usage")
        func requestContextCreation() throws {
            let testUserId = UUID()
            let bodyData = try JSONEncoder().encode(MockPostEndpoint.Body(data: "test"))
            let request = MockRequest(userId: testUserId, bodyData: bodyData)

            let context = RequestContext(
                request: request,
                query: EmptyCodable(),
                body: MockPostEndpoint.Body(data: "test")
            )

            #expect(context.request.userId == testUserId)
            #expect(context.body.data == "test")
        }

        @Test("Handler execution flow")
        func handlerExecutionFlow() async throws {
            var route = MockRoute()
            var handlerExecuted = false

            route.handler = { request in
                handlerExecuted = true
                return MockResponse()
            }

            let request = MockRequest()
            let response = try await route.handler(request)

            #expect(handlerExecuted == true)
            #expect(response.data == nil)
        }
    }
}### 4. Request/Response Protocols Suite (`RequestResponseTests`)

```swift
@Suite("Request/Response Protocol Tests")
struct RequestResponseTests {

    @Suite("RouteRequestKind Implementation")
    struct RouteRequestKindTests {
        @Test("User ID access")
        func userIdAccess() throws {
            let testUserId = UUID()
            let request = MockRequest(userId: testUserId)
            #expect(request.userId == testUserId)
        }

        @Test("Request body decoding with valid data")
        func requestBodyDecodingWithValidData() throws {
            let originalBody = MockPostEndpoint.Body(data: "test content")
            let bodyData = try JSONEncoder().encode(originalBody)
            let request = MockRequest(bodyData: bodyData)

            let decodedBody = try request.decodedRequestBody(MockPostEndpoint.Body.self)
            #expect(decodedBody.data == "test content")
        }

        @Test("Request body decoding with empty data")
        func requestBodyDecodingWithEmptyData() throws {
            let request = MockRequest()
            let emptyBody = try request.decodedRequestBody(EmptyCodable.self)
            #expect(emptyBody == EmptyCodable())
        }

        @Test("Request query decoding with valid data")
        func requestQueryDecodingWithValidData() throws {
            struct TestQuery: CoSendable {
                let search: String
            }

            let originalQuery = TestQuery(search: "test")
            let queryData = try JSONEncoder().encode(originalQuery)
            let request = MockRequest(queryData: queryData)

            let decodedQuery = try request.decodedRequestQuery(TestQuery.self)
            #expect(decodedQuery.search == "test")
        }

        @Test("Request query decoding with empty data")
        func requestQueryDecodingWithEmptyData() throws {
            let request = MockRequest()
            let emptyQuery = try request.decodedRequestQuery(EmptyCodable.self)
            #expect(emptyQuery == EmptyCodable())
        }
    }

    @Suite("RouteResponseKind Implementation")
    struct RouteResponseKindTests {
        @Test("Codable response creation")
        func codableResponseCreation() {
            let testData = MockPostEndpoint.Content(result: "success")
            let response = MockResponse.fromCodable(testData)

            if let responseData = response.data as? MockPostEndpoint.Content {
                #expect(responseData.result == "success")
            } else {
                #expect(Bool(false), "Response data should be MockPostEndpoint.Content")
            }
        }

        @Test("Stream response creation")
        func streamResponseCreation() async {
            let stream = AsyncStream<MockStreamEndpoint.Chunk> { continuation in
                continuation.yield(MockStreamEndpoint.Chunk(chunk: "test"))
                continuation.finish()
            }

            let response = MockResponse.fromStream(stream)
            #expect(response.data != nil)
        }

        @Test("Response initialization")
        func responseInitialization() {
            let response = MockResponse()
            #expect(response.data == nil)

            let responseWithData = MockResponse(data: "test")
            if let data = responseWithData.data as? String {
                #expect(data == "test")
            } else {
                #expect(Bool(false), "Response data should be String")
            }
        }
    }
}

### 5. Endpoint Group Suite (`EndpointGroupTests`)

```swift
### 5. Endpoint Group Suite (`EndpointGroupTests`)

```swift
@Suite("EndpointGroupProtocol Protocol Tests")
struct EndpointGroupTests {

    @Suite("Route Management")
    struct RouteManagementTests {
        @Test("Final routes combination")
        func finalRoutesCombination() {
            let mainRoutes = [MockRoute()]
            let additionalRoutes = [MockRoute(), MockRoute()]

            let group = MockEndpointGroup(routes: mainRoutes, additionalRoutes: additionalRoutes)
            let finalRoutes = group.finalRoutes

            #expect(finalRoutes.count == 3)
        }

        @Test("Empty additional routes default")
        func emptyAdditionalRoutesDefault() {
            let mainRoutes = [MockRoute()]
            let group = MockEndpointGroup(routes: mainRoutes)

            #expect(group.additionalRoutes.isEmpty)
            #expect(group.finalRoutes.count == 1)
        }

        @Test("Route concatenation order")
        func routeConcatenationOrder() {
            var route1 = MockRoute()
            route1.path = "/first"

            var route2 = MockRoute()
            route2.path = "/second"

            var route3 = MockRoute()
            route3.path = "/third"

            let group = MockEndpointGroup(
                routes: [route1, route2],
                additionalRoutes: [route3]
            )

            let finalRoutes = group.finalRoutes
            #expect(finalRoutes.count == 3)
            #expect(finalRoutes[0].path == "/first")
            #expect(finalRoutes[1].path == "/second")
            #expect(finalRoutes[2].path == "/third")
        }

        @Test("Empty endpoint group")
        func emptyEndpointGroup() {
            let group = MockEndpointGroup()
            #expect(group.finalRoutes.isEmpty)
        }
    }
}
````

### 6. Route Group Suite (`RouteGroupTests`)

````swift
### 6. Route Group Suite (`RouteGroupTests`)

```swift
@Suite("RouteGroup Protocol Tests")
struct RouteGroupTests {

    // Note: RouteGroup is a simple protocol with only routes and path properties
    // Most functionality is already tested through RouteBuilder and EndpointGroupProtocol tests

    @Suite("Basic Implementation")
    struct BasicImplementationTests {

        struct MockRouteGroup: RouteGroup {
            let path: String
            let testRoutes: [any RouteKind]

            var routes: Routes { testRoutes }

            init(path: String, routes: [any RouteKind] = []) {
                self.path = path
                self.testRoutes = routes
            }
        }

        @Test("Path property access")
        func pathPropertyAccess() {
            let group = MockRouteGroup(path: "/api/v1")
            #expect(group.path == "/api/v1")
        }

        @Test("Routes property access")
        func routesPropertyAccess() {
            let routes = [MockRoute()]
            let group = MockRouteGroup(path: "/test", routes: routes)
            #expect(group.routes.count == 1)
        }

        @Test("Empty route group")
        func emptyRouteGroup() {
            let group = MockRouteGroup(path: "/empty")
            #expect(group.routes.isEmpty)
        }
    }
}
````

### 7. Integration Tests Suite (`IntegrationTests`)

```swift
@Suite("SwiftAPICore Integration Tests")
struct IntegrationTests {

    @Suite("End-to-End Workflows")
    struct EndToEndWorkflowTests {
        @Test("Complete endpoint to route workflow")
        func completeEndpointToRouteWorkflow() async throws {
            // Create a mock endpoint group with actual routes
            let mockGroup = MockEndpointGroup(routes: [
                MockRoute().block(MockPostEndpoint.self) { context in
                    #expect(context.body.data == "integration test")
                    return MockPostEndpoint.Content(result: "success")
                }
            ])

            #expect(mockGroup.finalRoutes.count == 1)
            #expect(mockGroup.finalRoutes[0].path == "/mock/post")
            #expect(mockGroup.finalRoutes[0].method == .POST)
        }

        @Test("RouteBuilder with EndpointGroupProtocol integration")
        func routeBuilderWithEndpointGroupIntegration() {
            // Test that @RouteBuilder works properly in EndpointGroupProtocol context
            let routes = [MockRoute(), MockRoute()]
            let additionalRoutes = [MockRoute()]

            let group = MockEndpointGroup(routes: routes, additionalRoutes: additionalRoutes)

            // Should combine routes correctly
            #expect(group.finalRoutes.count == 3)

            // Test route builder functionality
            let emptyRoutes = RouteBuilder.buildBlock()
            let singleRoute = RouteBuilder.buildBlock(MockRoute())

            #expect(emptyRoutes.isEmpty)
            #expect(singleRoute.count == 1)
        }

        @Test("RequestContext with real endpoint data flow")
        func requestContextWithRealEndpointDataFlow() throws {
            let testUserId = UUID()
            let requestBody = MockPostEndpoint.Body(data: "context test")
            let bodyData = try JSONEncoder().encode(requestBody)

            let request = MockRequest(userId: testUserId, bodyData: bodyData)

            // Test RequestContext creation with real data
            let context = RequestContext(
                request: request,
                query: EmptyCodable(),
                body: requestBody
            )

            #expect(context.request.userId == testUserId)
            #expect(context.body.data == "context test")

            // Test that request can decode the body correctly
            let decodedBody = try request.decodedRequestBody(MockPostEndpoint.Body.self)
            #expect(decodedBody.data == "context test")
        }

        @Test("Async stream endpoint integration")
        func asyncStreamEndpointIntegration() async throws {
            var route = MockRoute()

            let configuredRoute = route.stream(MockStreamEndpoint.self) { context in
                AsyncStream<MockStreamEndpoint.Chunk> { continuation in
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk1"))
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk2"))
                    continuation.yield(MockStreamEndpoint.Chunk(chunk: "chunk3"))
                    continuation.finish()
                }
            }

            #expect(configuredRoute.path == "/mock/stream")
            #expect(configuredRoute.method == .POST)

            // Test that the handler is properly configured
            let request = MockRequest()
            let response = try await configuredRoute.handler(request)
            #expect(response.data != nil)
        }
    }
}
```

## Implementation Timeline

### Phase 1: Foundation Testing (Week 1)

- **Priority**: High
- **Focus**: Core protocol runtime behavior and mock implementations
- **Deliverables**:
  - Mock types implementation (MockEndpoint, MockRoute, MockRequest, MockResponse)
  - Endpoint protocol runtime behavior tests
  - RouteBuilder functionality tests
  - Container type serialization tests

### Phase 2: Route System Testing (Week 2)

- **Priority**: High
- **Focus**: Route configuration and RequestContext functionality
- **Deliverables**:
  - RouteKind configuration tests with real mock data
  - Request/Response protocol implementation tests
  - RequestContext creation and data flow validation

### Phase 3: Integration Testing (Week 3)

- **Priority**: Medium
- **Focus**: Cross-component interactions and real workflow testing
- **Deliverables**:
  - EndpointGroupProtocol route management tests
  - End-to-end workflow integration tests
  - Async stream endpoint functionality validation

### Phase 4: Edge Cases and Performance (Week 4)

- **Priority**: Medium
- **Focus**: Error conditions, edge cases, and performance validation
- **Deliverables**:
  - Error handling and invalid data tests
  - Performance benchmark tests with real mock data
  - Memory usage and concurrency safety validation

## Success Criteria

### Code Coverage Targets

- **Minimum**: 90% line coverage across all SwiftAPICore files
- **Target**: 95% line coverage with 100% critical path coverage
- **Branch Coverage**: 85% minimum for decision points

### Quality Metrics

- **Zero test failures** in CI/CD pipeline
- **All async tests complete** within 5 seconds
- **Memory leaks**: Zero detected in test execution
- **Thread safety**: All concurrent tests pass consistently

### Performance Benchmarks

- **Route building**: <1ms for typical endpoint groups
- **RequestContext creation**: <0.1ms per instance
- **Protocol method dispatch**: <0.01ms overhead
- **Type constraint validation**: Compile-time only (no runtime cost)

### Documentation Coverage

- **All public APIs** documented with examples
- **Test coverage reports** generated automatically
- **Performance metrics** tracked over time
- **Regression test suite** maintains historical compatibility

## CI/CD Integration

### Automated Testing Pipeline

```bash
# Core testing commands
swift test --package-path . --target SwiftAPICoreTests
swift test --enable-code-coverage
swift test --parallel --jobs 4
```

### Platform Testing Matrix

- **macOS**: 14.0+ (primary development platform)
- **iOS**: 17.0+ (mobile endpoint usage)
- **Linux**: Ubuntu 22.04+ (server deployment scenarios)

### Performance Regression Testing

- **Benchmark baselines** established in Phase 4
- **Automated performance alerts** for >10% regressions
- **Memory usage tracking** across test runs
- **Compile-time tracking** for type-heavy generic code

## Risk Mitigation

### Technical Risks

- **Generic constraint complexity**: Extensive compile-time validation tests
- **Protocol witness table performance**: Micro-benchmarking critical paths
- **Async/await integration**: Comprehensive concurrency testing
- **Type erasure issues**: Explicit any RouteKind testing

### Testing Infrastructure Risks

- **Mock object maintenance**: Automated mock generation where possible
- **Test data management**: Version-controlled test fixtures
- **CI/CD stability**: Redundant testing environments
- **Dependency management**: Locked dependency versions in tests

This comprehensive testing plan ensures SwiftAPICore's reliability, performance, and maintainability while establishing a solid foundation for the broader SwiftAPI framework ecosystem.
