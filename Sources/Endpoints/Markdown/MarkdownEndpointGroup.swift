import SwiftAPICore

public protocol MarkdownEndpointGroupProtocol: EndpointGroup {
    associatedtype Route: RouteKind

    typealias E1 = EP.Markdown.CreateMarkdown
    associatedtype S1: AsyncSequence where S1.Element == E1.ResponseChunk
    func createMarkdown(request: Route.Request, EndpointType: E1.Type) async throws -> S1
}

extension MarkdownEndpointGroupProtocol {
    public var groupedPath: String {
        "/markdown"
    }

    @RouteBuilder
    public var routes: Routes {
        Route()
            .stream(EP.Markdown.CreateMarkdown.self, handler: createMarkdown)
    }
}

extension EP {
    public enum Markdown {
        public struct CreateMarkdown: Endpoint {
            public var body: RequestBody

            static public var path: String { "/create" }
            static public var method: EndpointMethod { .POST }

            public init(body: RequestBody) {
                self.body = body
            }
        }
    }
}

extension EP.Markdown.CreateMarkdown {
    public struct RequestBody: CoSendable {
        public var text: String

        public init(text: String) {
            self.text = text
        }
    }

    public struct ResponseChunk: CoSendable {
        public var text: String

        public init(text: String) {
            self.text = text
        }
    }
}
