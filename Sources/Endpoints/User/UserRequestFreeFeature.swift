import SwiftAPICore

extension EP.User {
    public struct FetchFreeFeature: Endpoint {
        public static var path: String { "/check-feature-availability" }
        public var query: RequestQuery

        public init(query: RequestQuery) {
            self.query = query
        }
    }
}

extension EP.User.FetchFreeFeature {
    public enum Feature: String, CoSendable {
        case someFeature
        case anotherFeature
        case yetAnotherFeature
    }

    public struct RequestQuery: CoSendable {
        public let feature: Feature

        public init(feature: Feature) {
            self.feature = feature
        }
    }

    public struct ResponseContent: CoSendable {
        public let isAvailable: Bool

        public init(isAvailable: Bool) {
            self.isAvailable = isAvailable
        }
    }
}
