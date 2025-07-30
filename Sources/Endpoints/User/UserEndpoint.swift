//
//  UserEndpoint.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import SwiftAPICore

public protocol EndpointGroup {
    /// The name of the endpoint group
    static var name: String { get }
}

public enum EP {
    public enum User: EndpointGroup {
        public static var name: String {
            "user"
        }
    }
}

public protocol UserEndpointGroupProtocol: EndpointGroupProtocol {
    associatedtype Route: RouteKind

    typealias E1 = EP.User.FetchFreeFeature
    func fetchUserRequestFreeFeature(
        context: RequestContext<Route.Request, E1.Query, E1.Body>
    ) async throws -> E1.ResponseContent
}

extension UserEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route()
            .block(E1.self, handler: fetchUserRequestFreeFeature)
    }
}
