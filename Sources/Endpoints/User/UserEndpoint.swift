//
//  UserEndpoint.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import SwiftAPICore

public enum EP {
    public enum User {}
}

public protocol UserEndpointGroupProtocol: EndpointGroup {
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
            .block(EP.User.FetchFreeFeature.self, handler: fetchUserRequestFreeFeature)
    }
}
