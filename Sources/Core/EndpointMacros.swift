//
//  EndpointMacros.swift
//  swift-api
//
//  Created by GitHub Copilot on 2025/7/29.
//

import Foundation

/// A macro that automatically makes a struct conform to the Endpoint protocol.
///
/// This macro generates the required static properties and default implementations
/// for the Endpoint protocol.
///
/// Usage:
/// ```swift
/// @Endpoint("/words/suggested", .POST)
/// public struct FetchSuggestedWords {
///     public struct Body: Codable, Sendable {
///         public var text: String
///
///         public init(text: String) {
///             self.text = text
///         }
///     }
///
///     public struct ResponseContent: Codable, Sendable {
///         public var segments: [ContextModel.ContextSegment]
///
///         public init(segments: [ContextModel.ContextSegment]) {
///             self.segments = segments
///         }
///     }
/// }
/// ```
///
/// This will automatically generate:
/// - Conformance to Endpoint protocol
/// - Static `path` property with the provided path
/// - Static `method` property with the provided method
/// - Default `body` and `query` properties (if not defined)
/// - Public initializer (if Body is defined)
@attached(extension, conformances: Endpoint)
@attached(member, names: arbitrary)
public macro Endpoint(_ path: String, _ method: EndpointMethod) = #externalMacro(module: "Macros", type: "EndpointMacro")

/// A macro that modifies endpoint paths by prepending a group name.
///
/// This macro can be applied to enums to add a static groupName property,
/// or to extensions to modify the path of all Endpoint types within.
///
/// Usage:
/// ```swift
/// @EndpointGroup("words")
/// extension EP.Words {
///     // All endpoints in this extension will have "/words" prepended to their paths
/// }
/// ```
@attached(peer)
public macro EndpointGroup(_ name: String) = #externalMacro(module: "Macros", type: "EndpointGroupMacro")
