//
//  UserEndpoint.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import SwiftAPICore

public protocol UserEndpoint: Endpoint {}

extension UserEndpoint {
    public static var groupedPath: String { "/user" }
}

public enum EP {
    public enum User {}
}
