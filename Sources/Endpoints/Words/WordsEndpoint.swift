import ContextSharedModels
import SwiftAPICore

typealias CoSendable = Codable & Sendable & Hashable

extension EP {
    public enum Words {}
}

public protocol WordsEndpointGroupProtocol: EndpointGroup {
    associatedtype Route: RouteKind

    typealias E1 = EP.Words.FetchSuggestedWords
    @Sendable
    func fetchSuggestedWords(
        context: RequestContext<Route.Request, E1.RequestQuery, E1.RequestBody>
    ) async throws -> E1.ResponseContent

    typealias E2 = EP.Words.LookupWord
    @Sendable
    func lookupWord(
        context: RequestContext<Route.Request, E2.RequestQuery, E2.RequestBody>
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
    public struct FetchSuggestedWords: Endpoint {
        public static var path: String { "/words/suggested" }
        public var body: RequestBody

        public init(body: RequestBody) {
            self.body = body
        }

        public struct RequestBody: CoSendable {
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
    public struct LookupWord: Endpoint {
        public static var path: String { "/words/lookup" }
        public var body: RequestBody

        public init(body: RequestBody) {
            self.body = body
        }

        public struct RequestBody: CoSendable {
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
