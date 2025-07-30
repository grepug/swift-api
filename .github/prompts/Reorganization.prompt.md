---
mode: edit
---

# Swift Code Reorganization Guidelines

Please reorganize all Swift files in this project to follow open source best practices with proper structure, MARKs, and documentation.

## File Structure Requirements

### 1. Header Documentation

Each Swift file should start with a comprehensive header comment:

```swift
//
// FileName.swift
// ProjectName
//
// Created by Author on Date.
// Copyright © Year Company/Organization. All rights reserved.
//

/// Brief description of what this file contains and its purpose.
///
/// This file implements... [detailed description]
///
/// - Note: Any important notes about usage or implementation
/// - Warning: Any warnings about potential issues
/// - Since: Version when this was introduced
```

### 2. Import Organization

Group imports logically with proper spacing:

```swift
// MARK: - System Imports
import Foundation
import SwiftUI

// MARK: - Third-party Imports
import Alamofire
import SwiftAPICore

// MARK: - Internal Imports
import Core
import Utilities
```

### 3. MARK Comments Structure

Use MARK comments to organize code sections in this order:

```swift
// MARK: - Type Definitions

// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods

// MARK: - Protocol Conformance

// MARK: - Extensions
```

### 4. Documentation Standards

All public APIs must have documentation comments:

````swift
/// Brief description of the method/property
///
/// Longer description explaining the purpose, behavior, and any important details.
///
/// - Parameters:
///   - parameterName: Description of what this parameter does
///   - anotherParam: Description of another parameter
/// - Returns: Description of what this method returns
/// - Throws: Description of what errors this method might throw
/// - Complexity: Time/space complexity if relevant
/// - Note: Any additional notes
/// - Warning: Any warnings about usage
///
/// # Example
/// ```swift
/// let result = methodName(parameter: value)
/// ```
public func methodName(parameter: Type) throws -> ReturnType {
    // Implementation
}
````

### 5. Protocol Organization

Organize protocols with clear sections:

```swift
// MARK: - Protocol Definition

/// Protocol description
public protocol ProtocolName {
    // MARK: Associated Types
    associatedtype AssociatedType

    // MARK: Required Properties
    var requiredProperty: Type { get }

    // MARK: Required Methods
    func requiredMethod() -> ReturnType
}

// MARK: - Default Implementation

extension ProtocolName {
    /// Default implementation description
    public func methodWithDefault() {
        // Default implementation
    }
}
```

### 6. Struct/Class Organization

Structure types with clear sections:

```swift
// MARK: - TypeName

/// Type description
public struct/class TypeName {

    // MARK: - Type Properties

    // MARK: - Instance Properties

    // MARK: - Initialization

    /// Initializer description
    public init() {
        // Implementation
    }

    // MARK: - Public Methods

    // MARK: - Private Methods

}

// MARK: - TypeName + ProtocolName

extension TypeName: ProtocolName {
    // Protocol implementation
}

// MARK: - TypeName + Utilities

private extension TypeName {
    // Private utility methods
}
```

### 7. Endpoint Organization

For API endpoints, follow this structure:

```swift
// MARK: - Endpoint Protocol

/// Protocol defining the endpoint group behavior
public protocol EndpointGroupProtocol: EndpointGroupProtocol {
    // Protocol definition
}

// MARK: - Protocol Implementation

extension EndpointGroupProtocol {
    /// Group path configuration
    public var groupedPath: String {
        // Implementation
    }

    /// Route builder implementation
    @RouteBuilder
    public var routes: Routes {
        // Route definitions
    }
}

// MARK: - Endpoint Definitions

extension EP {
    /// Namespace for endpoint group
    public enum GroupName {

        // MARK: - EndpointName

        /// Endpoint description and purpose
        public struct EndpointName: Endpoint {
            // Endpoint implementation
        }
    }
}

// MARK: - Request/Response Models

extension EP.GroupName.EndpointName {

    // MARK: - Request Types

    /// Request body description
    public struct Body: CoSendable {
        // Properties and initializers
    }

    // MARK: - Response Types

    /// Response description
    public struct Response: CoSendable {
        // Properties and initializers
    }
}
```

### 8. Code Quality Guidelines

- **Line Length**: Keep lines under 120 characters
- **Spacing**: Use consistent spacing (1 line between methods, 2 lines between major sections)
- **Naming**: Use clear, descriptive names that explain intent
- **Comments**: Write comments that explain "why", not "what"
- **Error Handling**: Document all possible errors and their meanings

### 9. Function Signature Formatting

For long function signatures, use multi-line formatting with proper indentation:

```swift
/// Documentation for the function
func functionName<T, Body, Query>(
    _ path: String,
    method: EndpointMethod,
    query: Query,
    body: Body,
    decodingAs type: T.Type,
) async throws(APIClientError) -> T where T: Codable, Body: Encodable, Query: Encodable {
    // Implementation
}
```

**Key formatting rules:**

- Each parameter on its own line after the opening parenthesis
- Proper indentation (4 spaces) for parameters
- Closing parenthesis aligned with function keyword
- Generic constraints and return type on the same line as closing parenthesis
- Opening brace `{` stays on the same line as the function signature, never starts a new line
- **Trailing commas**: Add trailing commas after the last parameter in multi-line function signatures
- **Function calls**: Use trailing commas in multi-line function call parameter lists
- **Arrays/Collections**: Use trailing commas when each element is on its own line

**Examples:**

```swift
// Short signature - single line
func simpleMethod(parameter: String) -> Bool {
    // Implementation
}

// Long signature - multi-line
func complexMethod<T: Codable>(
    firstParameter: String,
    secondParameter: Int,
    thirdParameter: T,
    completion: @escaping (Result<T, Error>) -> Void,
) async throws -> T {
    // Implementation
}

// With generic constraints
func genericMethod<Input, Output>(
    input: Input,
    transformer: (Input) -> Output,
) -> Output where Input: Codable, Output: Sendable {
    // Implementation
}

// Protocol methods
func protocolMethod(
    request: Route.Request,
    endpointType: E1.Type,
) async throws -> E1.Response {
    // Implementation
}
```

### 10. Example of Well-Organized File

```swift
//
// SystemEndpointGroup.swift
// SwiftAPI
//
// Defines system-level endpoints for application configuration and updates.
// Copyright © 2025 Organization. All rights reserved.
//

import SwiftAPICore

// MARK: - SystemEndpointGroup Protocol

/// Protocol defining system endpoint group behavior
///
/// This protocol establishes the contract for system-level endpoints that handle
/// application configuration, version checking, and system status operations.
public protocol SystemEndpointGroupProtocol: EndpointGroupProtocol {
    associatedtype Route: RouteKind

    // MARK: Type Aliases
    typealias E1 = EP.System.CheckForceUpdate

    // MARK: Required Methods

    /// Checks if a force update is required for the given app version
    ///
    /// - Parameters:
    ///   - request: The route request containing app version information
    ///   - EndpointType: The endpoint type for type safety
    /// - Returns: Response indicating if update is required
    /// - Throws: Network or validation errors
    func checkForceUpdate(request: Route.Request, EndpointType: E1.Type) async throws -> E1.Response
}

// MARK: - Default Implementation

extension SystemEndpointGroupProtocol {

    /// The base path for all system endpoints
    public var groupedPath: String {
        "/system"
    }

    /// Route configuration for system endpoints
    @RouteBuilder
    public var routes: Routes {
        Route()
            .endpoint(EP.System.CheckForceUpdate.self, handler: checkForceUpdate)
    }
}

// MARK: - Endpoint Definitions

extension EP {

    /// System-level endpoints namespace
    public enum System {

        // MARK: - CheckForceUpdate Endpoint

        /// Endpoint for checking if app requires a force update
        ///
        /// This endpoint allows clients to check if their current app version
        /// requires a mandatory update before proceeding with normal operations.
        public struct CheckForceUpdate: Endpoint {

            // MARK: Properties
            public var body: Body

            // MARK: Endpoint Configuration
            static public var path: String { "/check-force-update" }
            static public var method: EndpointMethod { .POST }

            // MARK: Initialization

            /// Creates a new check force update request
            /// - Parameter body: The request body containing version information
            public init(body: Body) {
                self.body = body
            }
        }
    }
}

// MARK: - Request/Response Models

extension EP.System.CheckForceUpdate {

    // MARK: - Request Models

    /// Request body for force update check
    public struct Body: CoSendable {

        // MARK: Properties

        /// Current application version
        public var appVersion: String

        /// Platform identifier (iOS, Android, etc.)
        public var platform: String

        // MARK: Initialization

        /// Creates a new request body
        /// - Parameters:
        ///   - appVersion: The current app version
        ///   - platform: The platform identifier
        public init(appVersion: String, platform: String) {
            self.appVersion = appVersion
            self.platform = platform
        }
    }

    // MARK: - Response Models

    /// Response containing force update information
    public struct Response: CoSendable {

        // MARK: Properties

        /// Whether a force update is required
        public var forceUpdate: Bool

        /// Latest available version
        public var latestVersion: String

        /// Optional URL for downloading update
        public var updateUrl: String?

        /// Optional message to display to user
        public var message: String?

        // MARK: Initialization

        /// Creates a new response
        /// - Parameters:
        ///   - forceUpdate: Whether update is required
        ///   - latestVersion: Latest app version
        ///   - updateUrl: Optional download URL
        ///   - message: Optional user message
        public init(
            forceUpdate: Bool,
            latestVersion: String,
            updateUrl: String? = nil,
            message: String? = nil,
        ) {
            self.forceUpdate = forceUpdate
            self.latestVersion = latestVersion
            self.updateUrl = updateUrl
            self.message = message
        }
    }
}
```

## Action Items

1. **Review all Swift files** in the project
2. **Add proper header documentation** to each file
3. **Organize imports** according to the guidelines
4. **Add MARK comments** to structure the code
5. **Document all public APIs** with comprehensive comments
6. **Ensure consistent formatting** and spacing
7. **Add examples** in documentation where helpful
8. **Review and update** existing comments for clarity

This reorganization will make the codebase more maintainable, easier to navigate, and follow industry best practices for open source Swift projects.
