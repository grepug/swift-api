//
//  UserEndpoint.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import SwiftAPICore

public enum EP {
    @EndpointGroup("user")
    public enum User {}
}

public protocol UserEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.User.FetchFreeFeature

    func fetchUserRequestFreeFeature(context: Context<E1>) async throws -> E1.Content
}

extension UserEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, fetchUserRequestFreeFeature)
    }
}
