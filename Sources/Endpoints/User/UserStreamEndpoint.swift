import SwiftAPICore

extension EP.User {
    public struct UserStreamEndpoint: Endpoint {
        static public var path: String { "/user/xxx" }
        static public var method: EndpointMethod { .GET }
    }
}

extension EP.User.UserStreamEndpoint {
    public struct ResponseChunk: CoSendable {
        public var text: String
    }
}
