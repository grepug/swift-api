import SwiftAPICore

public protocol MarkdownEndpointGroupProtocol: EndpointGroup {
    associatedtype Route: RouteKind

    typealias E1 = EP.Markdown.CreateMarkdown
    typealias E2 = EP.Markdown.CreateMarkdownV2
    associatedtype S1: AsyncSequence where S1.Element == E1.ResponseChunk

    func createMarkdown(request: Route.Request, EndpointType: E1.Type) async throws -> S1
    func createMarkdownV2(request: Route.Request, EndpointType: E2.Type) async throws -> EP.Markdown.CreateMarkdownV2.ResponseContent
}

extension MarkdownEndpointGroupProtocol {
    @RouteBuilder
    public var routes: Routes {
        Route()
            .stream(EP.Markdown.CreateMarkdown.self, handler: createMarkdown)

        Route()
            .block(EP.Markdown.CreateMarkdownV2.self, handler: createMarkdownV2)
    }
}

extension EP {
    public enum Markdown {
        public struct CreateMarkdown: Endpoint {
            public var body: RequestBody

            static public var path: String { "/markdown/create" }
            static public var method: EndpointMethod { .POST }

            public init(body: RequestBody) {
                self.body = body
            }
        }
    }
}

extension EP.Markdown {
    public struct CreateMarkdownV2: Endpoint {
        public var body: RequestBody

        static public var path: String { "/markdown/create_v2" }
        static public var method: EndpointMethod { .POST }

        public init(body: RequestBody) {
            self.body = body
        }
    }
}

extension EP.Markdown.CreateMarkdown {
    public struct RequestBody: CoSendable {
        public enum Source: String, CoSendable {
            case epub
            case pdf
            case web
            case manualInput
        }

        public var texts: [String]
        public var source: Source
        public var isEnglish: Bool

        public init(texts: [String], source: Source, isEnglish: Bool) {
            self.texts = texts
            self.source = source
            self.isEnglish = isEnglish
        }
    }

    public struct ResponseChunk: CoSendable {
        public var markdown: String

        public init(markdown: String) {
            self.markdown = markdown
        }
    }
}

extension EP.Markdown.CreateMarkdownV2 {
    public struct RequestBody: CoSendable {
        public var texts: [String]

        public init(texts: [String]) {
            self.texts = texts
        }
    }

    public struct ResponseContent: CoSendable {
        public var markdown: String

        public init(markdown: String) {
            self.markdown = markdown
        }
    }
}
