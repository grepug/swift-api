# SwiftAPI Codebase Guide for AI Agents

## Architecture Overview

This is a Swift Package Manager library implementing a type-safe API client and endpoint framework. The architecture follows a modular design with three main layers:

### Core Components

- **SwiftAPICore**: Core protocols and types (`Sources/Core/`)
- **SwiftAPIClient**: HTTP client implementation (`Sources/Client/`)
- **ContextEndpoints**: Concrete endpoint definitions (`Sources/Endpoints/`)

### Key Design Patterns

#### 1. EP Namespace Pattern

All endpoints are defined under the `EP` enum namespace with nested enums for logical grouping:

```swift
extension EP {
    public enum System {
        public struct AppConfig: Endpoint { ... }
    }
}
```

#### 2. Protocol-Driven Endpoint Groups

Each endpoint group follows this pattern:

```swift
public protocol SystemEndpointGroupProtocol: EndpointGroup {
    associatedtype Route: RouteKind
    typealias E1 = EP.System.AppConfig
    func fetchAppConfig(context: RequestContext<Route.Request, E1.Query, E1.Body>) async throws -> E1.ResponseContent
}
```

#### 3. RequestContext Pattern

Handler functions receive a `RequestContext` that wraps the route request with decoded query and body:

```swift
RequestContext<Route.Request, E.Query, E.Body>
```

#### 4. Dual Response Types

Endpoints support two response modes:

- **Block**: Single response (`ResponseContent`)
- **Stream**: Chunked responses (`ResponseChunk` via `AsyncSequence`)

### Route Building System

Uses `@RouteBuilder` result builder for declarative route configuration:

```swift
@RouteBuilder
public var routes: Routes {
    Route()
        .block(EP.System.AppConfig.self, handler: fetchAppConfig)
    Route()
        .stream(EP.Markdown.CreateMarkdown.self, handler: createMarkdown)
}
```

## File Organization Conventions

### Endpoint Structure

- Protocol definition with handler methods
- Default implementation with routes configuration
- EP namespace extension with endpoint struct
- Request/Response model extensions

### Required Associated Types

- `Body: CoSendable` (default: `EmptyCodable`)
- `Query: CoSendable` (default: `EmptyCodable`)
- `ResponseContent: CoSendable` (default: `EmptyCodable`)
- `ResponseChunk: CoSendable` (default: `EmptyCodable`)

## Development Workflows

### Adding New Endpoints

1. Define protocol in appropriate group file (e.g., `SystemEndpointGroup.swift`)
2. Add handler method with `RequestContext` parameter
3. Extend `EP` namespace with endpoint struct
4. Create request/response models as extensions
5. Update routes configuration with `.block()` or `.stream()`

### Testing Strategy

- Mock clients implement `APIClientKind` protocol
- Use `@testable import` for ContextEndpoints, SwiftAPIClient, SwiftAPICore
- Test both endpoint configuration and handler logic separately
- Always use `swift test` directly in terminal rather than the runTests tool

### Build Commands

```bash
swift build                 # Build all targets
swift test                  # Run test suite
swift package resolve      # Resolve dependencies
```

## Code Style Requirements

### Function Signatures

Use trailing commas and multi-line formatting for complex signatures:

```swift
func data<T, Body, Query>(
    _ path: String,
    method: EndpointMethod,
    query: Query,
    body: Body,
    decodingAs type: T.Type,
) async throws(APIClientError) -> T where T: Codable, Body: Encodable, Query: Encodable
```

### MARK Organization

Structure files with these sections in order:

- System/Third-party/Internal Imports
- Protocol Definition
- Default Implementation
- Endpoint Definitions
- Request/Response Models

## Critical Integration Points

### Dependencies

- **ErrorKit**: Error handling and user-friendly messages
- **ConcurrencyUtils**: Async utilities and threading
- **ContextSharedModels**: Shared data models (in ContextEndpoints only)

### Type Safety

- `CoSendable` typealias ensures `Sendable & Codable & Hashable`
- Generic constraints enforce proper endpoint typing
- `@MainActor` on client protocols for thread safety

### Error Handling

All client operations use typed throws with `APIClientError`:

- `invalidResponse`, `serverError`, `decodingError`
- `invalidAccessToken`, `urlSessionError`, `caught`

## Common Patterns to Follow

When implementing endpoints, always:

1. Use `RequestContext` for handler parameters
2. Define both streaming and block variants if applicable
3. Include comprehensive documentation with parameter descriptions
4. Follow the EP namespace organization
5. Use trailing commas in multi-line parameter lists
6. Test both success and error scenarios
