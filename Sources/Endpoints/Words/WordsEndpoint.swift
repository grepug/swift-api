import ContextSharedModels
import Foundation
import SwiftAPICore

extension EP {
    @EndpointGroup("words")
    public enum Words {}
}

public protocol WordsEndpointGroupProtocol: EndpointGroupProtocol {
    typealias E1 = EP.Words.FetchSuggestedWords
    typealias E2 = EP.Words.LookupWord
    typealias E3 = EP.Words.CreateSegment
    typealias E4 = EP.Words.SameTextSegments
    typealias E5 = EP.Words.SameExistingTokenRanges

    associatedtype S1: AsyncSequence where S1.Element == E1.Chunk, S1: Sendable

    func streamSuggestedWords(context: Context<E1>) async throws -> S1

    func lookupWord(context: Context<E2>) async throws -> E2.Content

    func createSegment(context: Context<E3>) async throws -> E3.Content

    func sameTextSegments(context: Context<E4>) async throws -> E4.Content

    func sameExistingTokenRanges(context: Context<E5>) async throws -> E5.Content
}

extension WordsEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().stream(E1.self, streamSuggestedWords)
        Route().block(E2.self, lookupWord)
        Route().block(E3.self, createSegment)
        Route().block(E4.self, sameTextSegments)
        Route().block(E5.self, sameExistingTokenRanges)
    }
}

extension EP.Words {
    @Endpoint("suggested", .POST)
    public struct FetchSuggestedWords: Endpoint {
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
    public struct LookupWord: Endpoint {
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

extension EP.Words {
    @Endpoint("create-segment", .PUT)
    public struct CreateSegment: Endpoint {
        public var body: Body

        @DTO
        public struct Body {
            public var contextId: UUID
            public var segment: ContextModel.ContextSegment
        }
    }
}

extension EP.Words {
    @Endpoint("same-text-segments", .POST)
    public struct SameTextSegments: Endpoint {
        public var body: Body

        @DTO
        public struct Body {
            public var segmentId: UUID?
            public var text: String?
        }

        @DTO
        public struct Content {
            public var segments: [ContextModel.ContextSegment]
        }
    }
}

extension EP.Words {
    @Endpoint("same-existing-token-ranges", .POST)
    public struct SameExistingTokenRanges: Endpoint {
        public var body: Body

        @DTO
        public struct Body {
            public var text: String
            public var contextId: UUID
        }

        @DTO
        public struct Content {
            public var range: [CharacterRange]
        }
    }
}
