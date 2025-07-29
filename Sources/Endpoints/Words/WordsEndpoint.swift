import ContextSharedModels
import SwiftAPICore

typealias CoSendable = Codable & Sendable & Hashable

extension EP {
    public enum Words: EndpointGroupNaming {
        public static let groupName = "words"
    }
}

public protocol WordsEndpointGroupProtocol: EndpointGroup {
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
    ) async throws -> EP.Words.LookupWord.ResponseContent
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
    @Endpoint("/words/suggested", .POST)
    public struct FetchSuggestedWords {
        public var body: Body

        public struct Body: CoSendable {
            public var text: String

            public init(text: String) {
                self.text = text
            }
        }

        public struct ResponseContent: CoSendable {
            public var segments: [ContextModel.ContextSegment]

            public init(segments: [ContextModel.ContextSegment]) {
                self.segments = segments
            }
        }
    }
}

extension EP.Words {
    @Endpoint("/words/lookup", .POST)
    public struct LookupWord {
        public var body: Body

        public struct Body: CoSendable {
            public var text: String
            public var token: ContextModel.TokenItem

            public init(text: String, token: ContextModel.TokenItem) {
                self.text = text
                self.token = token
            }
        }

        public struct ResponseContent: CoSendable {
            public var segment: ContextModel.ContextSegment

            public init(segment: ContextModel.ContextSegment) {
                self.segment = segment
            }
        }
    }
}
