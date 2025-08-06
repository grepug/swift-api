import Foundation
import SwiftAPICore

extension EP {
    @EndpointGroup("admin")
    public enum Admin {}
}

// MARK: - AdminEndpointGroup Protocol

/// Protocol defining admin endpoint group behavior
///
/// This protocol establishes the contract for administrative endpoints that handle
/// privileged operations requiring admin authentication.
public protocol AdminEndpointGroupProtocol: EndpointGroupProtocol {

    // MARK: Type Aliases
    typealias E1 = EP.Admin.SetAppReviewBuild
    typealias E2 = EP.Admin.GetAppReviewBuild

    // MARK: Required Methods

    func setAppReviewBuild(context: Context<E1>) async throws -> E1.Content
    func getAppReviewBuild(context: Context<E2>) async throws -> E2.Content
}

// MARK: - Default Implementation

extension AdminEndpointGroupProtocol {

    /// Route configuration for admin endpoints
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, setAppReviewBuild)
        Route().block(E2.self, getAppReviewBuild)
    }
}

extension EP.Admin {
    @Endpoint("app-review-build", .POST)
    public struct SetAppReviewBuild {
        public var body: Body

        @DTO
        public struct Body {
            public var appBuild: Int
        }
    }

    @Endpoint("app-review-build", .GET)
    public struct GetAppReviewBuild {
        @DTO
        public struct Content {
            public let appBuild: Int
        }
    }
}
