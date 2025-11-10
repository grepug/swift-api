import ContextSharedModels
import Foundation
import SwiftAPICore

extension EP {
    @EndpointGroup("llm")
    public enum LLM {}
}

/// Protocol defining the LLM endpoint group operations
///
/// This protocol establishes the contract for LLM-related API endpoints,
/// including chat completions, text generation, and streaming responses.
public protocol LLMEndpointGroupProtocol: EndpointGroupProtocol {
    // Add your endpoint typealiases and methods here
    typealias E1 = EP.LLM.TextCompletion
    func textCompletion(context: Context<E1>) async throws -> E1.Content
}

extension LLMEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route().block(E1.self, textCompletion)
    }
}

extension EP.LLM {
    @Endpoint("text-completion", .POST)
    public struct TextCompletion {
        public var body: Body

        @DTO
        public enum Key: String {
            case studyNotes
            case translation
            case thesaurus
            case memorizingHelper
            case collocations
            case usages
        }

        @DTO
        public struct Body {
            public var key: Key
            public var input: CodableContainer
        }

        @DTO
        public struct Content {
            public var content: String
        }
    }
}
