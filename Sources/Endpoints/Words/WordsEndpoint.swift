import ContextSharedModels
import SwiftAPICore

extension EP {
    @EndpointGroup("words")
    public enum Words {}
}

public protocol WordsEndpointGroupProtocol: EndpointGroupProtocol {
    associatedtype Route: RouteKind

    typealias E1 = EP.Words.FetchSuggestedWords
    typealias E2 = EP.Words.LookupWord

    associatedtype S1: AsyncSequence where S1.Element == E1.Chunk

    func streamSuggestedWords(
        context: RequestContext<Route.Request, E1.Query, E1.Body>
    ) async throws -> S1

    func lookupWord(
        context: RequestContext<Route.Request, E2.Query, E2.Body>
    ) async throws -> E2.Content
}

extension WordsEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().stream(E1.self, streamSuggestedWords)
        Route().block(E2.self, lookupWord)
    }
}

extension EP.Words {
    @Endpoint("suggested", .POST)
    public struct FetchSuggestedWords {
        public var body: Body

        @DTO
        public struct Body {
            public var text: String
        }

        @DTO
        public struct Chunk {
            public var segments: [ContextModel.ContextSegment]
            public var finished: Bool
        }
    }
}

extension EP.Words {
    @Endpoint("lookup", .POST)
    public struct LookupWord {
        public var body: Body

        @DTO
        public struct Body {
            public var text: String
            public var token: ContextModel.TokenItem
        }

        @DTO
        public struct Content {
            public var segment: ContextModel.ContextSegment
        }
    }
}
