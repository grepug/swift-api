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
///     struct Body: Codable, Sendable {
///         public var text: String               // Properties must be explicitly public
///     }
///
///     struct ResponseContent: Codable, Sendable {
///         public var segments: [ContextModel.ContextSegment]
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
/// - Processes properties with no access modifier or 'public' access modifier
/// Note: Properties must be manually declared as public for external use
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

/// A macro that automatically makes a struct or enum conform to common DTO protocols and generates initializers.
///
/// This macro automatically adds conformance to Hashable, Codable, and Sendable protocols.
/// For structs, it also generates a public initializer with all properties that don't have default values.
/// For enums, it only adds protocol conformance (no initializer needed).
///
/// Usage with struct:
/// ```swift
/// @DTO
/// public struct Body {
///     public var text: String                    // Properties must be explicitly public
///     public var token: ContextModel.TokenItem   // For external package usage
///     public var count: Int = 5                  // Default values become default parameters
/// }
/// ```
///
/// Usage with enum:
/// ```swift
/// @DTO
/// public enum Feature {  // Only the type needs 'public'
///     case importFulltext
///     case addContextSegment
/// }
/// ```
///
/// This will automatically generate:
/// - Conformance to Hashable, Codable, Sendable protocols
/// - For structs: Public initializer with all properties without default values
/// - For enums: Only protocol conformance (no initializer)
/// - Processes properties with no access modifier or 'public' access modifier
/// Note: Properties must be manually declared as public for external use
@attached(extension, conformances: Hashable, Codable, Sendable)
@attached(member, names: arbitrary)
public macro DTO() = #externalMacro(module: "Macros", type: "DTOMacro")
