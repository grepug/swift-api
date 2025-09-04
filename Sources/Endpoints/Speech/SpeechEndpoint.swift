import ContextSharedModels
import ErrorKit
import Foundation
import SwiftAPICore

extension EP {
    @EndpointGroup("speech")
    public enum Speech {}
}

public protocol SpeechEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.Speech.FetchPlayItems
    typealias E2 = EP.Speech.GeneratePlayItemAsset
    typealias E3 = EP.Speech.AddPlayLog
    typealias E4 = EP.Speech.GetUsage
    typealias E5 = EP.Speech.GetDemo

    func fetchPlayItems(_ context: Context<E1>) async throws -> E1.Content
    func generatePlayItemAsset(_ context: Context<E2>) async throws(E2.Error) -> E2.Content
    func addPlayLog(_ context: Context<E3>) async throws -> E3.Content
    func getUsage(_ context: Context<E4>) async throws(E4.Error) -> E4.Content
    func getDemo(_ context: Context<E5>) async throws -> E5.Content
}

extension SpeechEndpointGroupProtocol {
    @RouteBuilder
    public var routes: [any RouteKind] {
        Route().block(E1.self, fetchPlayItems)
        Route().block(E2.self, generatePlayItemAsset)
        Route().block(E3.self, addPlayLog)
        Route().block(E4.self, getUsage)
        Route().block(E5.self, getDemo)
    }
}

extension EP.Speech {
    @Endpoint("context-play-items", .POST)
    public struct FetchPlayItems {
        public var body: Body

        @DTO
        public struct Body {
            @DTO
            public enum Filter {
                case collection(UUID)
                case fulltext(UUID)
            }

            public var filter: Filter
            public var count: Int
        }

        @DTO
        public struct Content {
            public let items: [ContextModel.PlayItem]
            public let playedCounts: [Int]
            public let isEligible: Bool
        }
    }

    @Endpoint("generate-play-item-asset", .POST)
    public struct GeneratePlayItemAsset {
        public var body: Body

        @DTO
        public struct Body {
            public let playItemId: UUID
            public var voiceId: String = "Boyan_new_platform"
        }

        @DTO
        public struct Content {
            public let item: ContextModel.PlayItem
        }

        public enum Error: CodableError {
            case usageLimitExceeded(current: Int, limit: Int)
            case noActiveSubscription
            case other(message: String)
        }
    }

    @Endpoint("add-play-log", .POST)
    public struct AddPlayLog {
        public var body: Body

        @DTO
        public struct Body {
            public let playItemId: UUID
        }
    }

    @Endpoint("usage", .GET)
    public struct GetUsage {

        @DTO
        public struct Content {
            public let usage: Int
            public let limit: Int
            public let nextReset: Date
        }

        public enum Error: CodableError {
            case noSubscription
            case other(message: String)
        }
    }

    @Endpoint("demo-data", .GET)
    public struct GetDemo {
        @DTO
        public struct Content {
            public let collectionItem: ContextModel.Collection
            public let contextItems: [ContextModel.Context]
            public let playItems: [ContextModel.PlayItem]
            public let appConfigPaths: [UUID: String]
        }
    }

}
