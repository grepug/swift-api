import Foundation
import SwiftAPICore

extension EP.User {
    @Endpoint("/user/check-feature-availability", .GET)
    public struct FetchFreeFeature {
        public var query: Query

        public init(query: Query) {
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

        public var localizedName: String {
            switch self {
            case .importFulltext: "导入文章"
            case .addContextSegment: "添加生词"
            case .contextTranslation: "翻译"
            case .contextStudyNote: "语境分析"
            case .segmentStudyNote: "单词学习"
            }
        }
    }

    public struct FeatureLimitInfo: CoSendable {
        public var featureCanUse: [Feature: Bool] = [:]
        public var featureNextAvailableDate: [Feature: Date?] = [:]

        public init() {}
    }

    public struct Query: CoSendable {
        public enum StringBool: String, CoSendable {
            case `true`
            case `false`

            public var bool: Bool {
                self == .true
            }
        }

        public let feature: Feature
        public let useOne: StringBool

        public init(feature: Feature, useOne: Bool) {
            self.feature = feature
            self.useOne = useOne ? .true : .false
        }
    }

    public struct ResponseContent: CoSendable {
        public let info: FeatureLimitInfo

        public init(info: FeatureLimitInfo) {
            self.info = info
        }
    }
}
