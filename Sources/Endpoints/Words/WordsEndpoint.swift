import ContextSharedModels
import SwiftAPICore

extension EP {
    @EndpointGroup("words")
    public enum Words {}
}

public protocol WordsEndpointGroupProtocol: EndpointGroupProtocol {
    associatedtype Route: RouteKind

    typealias E1 = EP.Words.FetchSuggestedWords
    @Sendable
    func fetchSuggestedWords(
        context: RequestContext<Route.Request, E1.Query, E1.Body>
    ) async throws -> E1.ResponseContent

    typealias E2 = EP.Words.LookupWord
    @Sendable
    func lookupWord(
        context: RequestContext<Route.Request, E2.Query, E2.Body>
    ) async throws -> E2.ResponseContent
}

extension WordsEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route()
            .block(EP.Words.FetchSuggestedWords.self, handler: fetchSuggestedWords)

        Route()
            .block(EP.Words.LookupWord.self, handler: lookupWord)
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
        public struct ResponseContent {
            public var segments: [ContextModel.ContextSegment]
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
        public struct ResponseContent {
            public var segment: ContextModel.ContextSegment
        }
    }
}
