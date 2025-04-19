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
    func fetchUserRequestFreeFeature(request: Route.Request, EndpointType: E1.Type) async throws -> E1.ResponseContent
}

extension UserEndpointGroupProtocol {
    public var groupedPath: String {
        "/user"
    }

    @RouteBuilder
    public var routes: Routes {
        Route()
            .block(EP.User.FetchFreeFeature.self, handler: fetchUserRequestFreeFeature)
    }
}
