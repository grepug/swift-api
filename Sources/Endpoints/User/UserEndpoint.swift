//
//  UserEndpoint.swift
//  swift-api
//
//  Created by Kai Shao on 2025/4/17.
//

import Foundation
import SwiftAPICore

public enum EP {
    @EndpointGroup("user")
    public enum User {}
}

public protocol UserEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.User.FetchFreeFeature
    typealias E2 = EP.User.UpsertUserInfo
    typealias E3 = EP.User.UpdateAPNSDeviceToken

    func fetchUserRequestFreeFeature(context: Context<E1>) async throws -> E1.Content
    func upsertUserInfo(context: Context<E2>) async throws -> E2.Content
    func updateAPNSDeviceToken(context: Context<E3>) async throws -> E3.Content
}

extension UserEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, fetchUserRequestFreeFeature)
        Route().block(E2.self, upsertUserInfo)
        Route().block(E3.self, updateAPNSDeviceToken)
    }
}

extension EP.User {
    @Endpoint("upsert-user-info", .POST)
    public struct UpsertUserInfo {
        public var body: Body

        @DTO public struct Body {
            public var userRegistrationDate: Date
            public var deviceId: UUID
            public var userName: String?
            public var modelName: String?
            public var marketingModelName: String?
            public var deviceName: String?
            public var appVersion: String?
            public var appBuild: String?
            public var osVersion: String?
            public var osName: String?
            public var apnsDeviceToken: String?
            public var timeZoneOffsetToUTCInMinutes: Int?
        }
    }

    @Endpoint("update-apns-device-token", .POST)
    public struct UpdateAPNSDeviceToken {
        public var body: Body

        @DTO public struct Body {
            public var deviceId: UUID
            public var apnsDeviceToken: String
        }
    }
}
