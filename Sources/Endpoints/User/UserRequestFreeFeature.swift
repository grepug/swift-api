import ContextSharedModels
import Foundation
import SwiftAPICore

extension EP.User {
    @Endpoint("check-feature-availability", .GET)
    public struct FetchFreeFeature {
        public var query: Query
    }
}

extension EP.User.FetchFreeFeature {
    public typealias Feature = FreeFeature
    public typealias FeatureLimitInfo = FreeFeatureLimitInfo

    @DTO
    public struct Query {
        @DTO
        public enum StringBool: String {
            case `true`
            case `false`

            public var bool: Bool {
                self == .true
            }
        }

        public let feature: Feature
        public let useOne: StringBool
    }

    @DTO
    public struct Content {
        public let info: FeatureLimitInfo
    }
}
