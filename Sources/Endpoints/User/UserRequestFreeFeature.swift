import Foundation
import SwiftAPICore

extension EP.User {
    @Endpoint("/user/check-feature-availability", .GET)
    public struct FetchFreeFeature {
        public var query: Query
    }
}

extension EP.User.FetchFreeFeature {
    @DTO
    public enum Feature: String, CaseIterable {
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

    @DTO
    public struct FeatureLimitInfo {
        public var featureCanUse: [Feature: Bool] = [:]
        public var featureNextAvailableDate: [Feature: Date?] = [:]
    }

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

        public init(feature: Feature, useOne: Bool) {
            self.feature = feature
            self.useOne = useOne ? .true : .false
        }
    }

    @DTO
    public struct ResponseContent {
        public let info: FeatureLimitInfo
    }
}
