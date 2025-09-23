import ContextSharedModels
import Foundation
import SwiftAPICore

public protocol SoundEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.Sound.FetchSound

    func fetchSound(context: Context<E1>) async throws -> E1.Content
}

extension SoundEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, fetchSound)
    }
}

extension EP {
    @EndpointGroup("sound")
    public enum Sound {
        @Endpoint("sound", .GET)
        public struct FetchSound {
            public var query: Query

            @DTO
            public struct Query {
                public let text: String
            }

            @DTO
            public struct Content {
                public let item: SoundItem?
            }
        }
    }
}
