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

    func fetchPlayItems(_ context: Context<E1>) async throws -> E1.Content
    func generatePlayItemAsset(_ context: Context<E2>) async throws(E2.Error) -> E2.Content
    func addPlayLog(_ context: Context<E3>) async throws -> E3.Content
}

extension SpeechEndpointGroupProtocol {
    @RouteBuilder
    public var routes: [any RouteKind] {
        Route().block(E1.self, fetchPlayItems)
        Route().block(E2.self, generatePlayItemAsset)
        Route().block(E3.self, addPlayLog)
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
}
