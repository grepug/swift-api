import SwiftAPICore

extension EP.User {
    struct UserStreamEndpoint: Endpoint {
        static public var path: String { "/xxx" }
        static public var method: EndpointMethod { .GET }
    }
}

extension EP.User.UserStreamEndpoint {
    struct ResponseChunk: CoSendable {
        var text: String
    }
}
