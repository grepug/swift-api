import Foundation
import SwiftAPICore

extension EP.User {
    public struct FetchFreeFeature: Endpoint {
        public static var path: String { "/user/check-feature-availability" }
        public var query: RequestQuery

        public init(query: RequestQuery) {
            self.query = query
        }
    }
}

extension EP.User.FetchFreeFeature {
    public enum Feature: String, CoSendable, CaseIterable {
        case importFulltext
        case addContextSegment
        case contextTranslation
        case contextStudyNote
        case segmentStudyNote

        public var countLimit: Int {
            switch self {
            case .importFulltext: 5
            case .addContextSegment: 100
            case .contextTranslation: 3
            case .contextStudyNote: 3
            case .segmentStudyNote: 10
            }
        }
    }

    public struct FeatureLimitInfo: CoSendable {
        public var featureCanUse: [Feature: Bool] = [:]
        public var featureNextAvailableDate: [Feature: Date?] = [:]

        public init() {}
    }

    public struct RequestQuery: CoSendable {
        public let feature: Feature

        public init(feature: Feature) {
            self.feature = feature
        }
    }

    public struct ResponseContent: CoSendable {
        public let info: FeatureLimitInfo

        public init(info: FeatureLimitInfo) {
            self.info = info
        }
    }
}
