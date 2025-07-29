//
// MarkdownEndpointGroup.swift
// SwiftAPI
//
// Defines markdown processing endpoints for text-to-markdown conversion.
// Copyright © 2025 Organization. All rights reserved.
//

/// Markdown endpoint group implementation for text processing and conversion.
///
/// This file provides endpoints for converting various text sources (EPUB, PDF, web content)
/// into markdown format, supporting both streaming and block responses.
///
/// - Note: Supports multiple text sources and languages
/// - Since: 1.0.0

// MARK: - Third-party Imports

import SwiftAPICore

// MARK: - MarkdownEndpointGroup Protocol

/// Protocol defining markdown endpoint group behavior
///
/// This protocol establishes the contract for markdown processing endpoints that handle
/// text-to-markdown conversion with support for streaming and block responses.
public protocol MarkdownEndpointGroupProtocol: EndpointGroup {
    associatedtype Route: RouteKind

    // MARK: Type Aliases
    typealias E1 = EP.Markdown.CreateMarkdown
    typealias E2 = EP.Markdown.CreateMarkdownV2
    associatedtype S1: AsyncSequence where S1.Element == E1.ResponseChunk

    // MARK: Required Methods

    /// Creates markdown from text using streaming response
    ///
    /// - Parameters:
    ///   - request: The route request containing text data
    ///   - EndpointType: The endpoint type for type safety
    /// - Returns: An async sequence of markdown chunks
    /// - Throws: Processing or network errors
    func createMarkdown(
        context: RequestContext<Route.Request, E1.Query, E1.Body>,
    ) async throws -> S1

    /// Creates markdown from text using block response (V2)
    ///
    /// - Parameters:
    ///   - request: The route request containing text data
    ///   - EndpointType: The endpoint type for type safety
    /// - Returns: Complete markdown response content
    /// - Throws: Processing or network errors
    func createMarkdownV2(
        context: RequestContext<Route.Request, E2.Query, E2.Body>,
    ) async throws -> E2.ResponseContent
}

// MARK: - Default Implementation

extension MarkdownEndpointGroupProtocol {

    /// Route configuration for markdown endpoints
    ///
    /// @Sendable (RequestContext<Self.Route.Request, EP.Markdown.CreateMarkdown.Query, EP.Markdown.CreateMarkdown.Body>, EP.Markdown.CreateMarkdown.Type) async throws -> Self.S1
    /// @Sendable (RequestContext<Self.Route.Request, EmptyCodable, EP.Markdown.CreateMarkdown.Body>, EP.Markdown.CreateMarkdown.Type) async throws -> Self.S1
    /// @Sendable (RequestContext<Self.Route.Request, EP.Markdown.CreateMarkdown.Query, EP.Markdown.CreateMarkdown.Body>) async throws -> Self.S1
    @RouteBuilder
    public var routes: Routes {
        Route()
            .stream(EP.Markdown.CreateMarkdown.self, handler: createMarkdown)

        Route()
            .block(EP.Markdown.CreateMarkdownV2.self, handler: createMarkdownV2)
    }
}

// MARK: - Endpoint Definitions

extension EP {

    /// Markdown processing endpoints namespace
    public enum Markdown {

        // MARK: - CreateMarkdown Endpoint

        /// Endpoint for streaming markdown creation from text
        ///
        /// This endpoint processes text from various sources and streams back
        /// markdown content as it's generated, allowing for real-time processing.
        @Endpoint("/markdown/create", .POST)
        public struct CreateMarkdown {

            // MARK: Properties
            public var body: Body

            // MARK: Initialization

            /// Creates a new markdown creation request
            /// - Parameter body: The request body containing text data
            public init(body: Body) {
                self.body = body
            }
        }
    }
}

// MARK: - CreateMarkdownV2 Endpoint

extension EP.Markdown {

    /// Endpoint for block markdown creation from text (V2)
    ///
    /// This endpoint processes text and returns the complete markdown
    /// content in a single response, suitable for smaller text inputs.
    @Endpoint("/markdown/create_v2", .POST)
    public struct CreateMarkdownV2 {

        // MARK: Properties
        public var body: Body

        /// Creates a new markdown creation request (V2)
        /// - Parameter body: The request body containing text data
        public init(body: Body) {
            self.body = body
        }
    }
}

// MARK: - CreateMarkdown Request/Response Models

extension EP.Markdown.CreateMarkdown {

    // MARK: - Request Types

    /// Request body for markdown creation
    @DTO
    public struct Body {

        // MARK: - Source Type

        /// Enumeration of supported text sources
        @DTO
        public enum Source: String {
            case epub
            case pdf
            case web
            case manualInput
        }

        // MARK: Properties

        /// Array of text content to convert
        public var texts: [String]

        /// Source type of the text content
        public var source: Source

        /// Whether the content is in English
        public var isEnglish: Bool

        // MARK: Initialization

        /// Creates a new request body
        /// - Parameters:
        ///   - texts: Array of text content to process
        ///   - source: Source type of the content
        ///   - isEnglish: Language indicator for processing
        public init(
            texts: [String],
            source: Source,
            isEnglish: Bool,
        ) {
            self.texts = texts
            self.source = source
            self.isEnglish = isEnglish
        }
    }

    // MARK: - Response Types

    /// Response chunk for streaming markdown content
    @DTO
    public struct ResponseChunk {

        // MARK: Properties

        /// Generated markdown content chunk
        public var markdown: String

        // MARK: Initialization

        /// Creates a new response chunk
        /// - Parameter markdown: The markdown content chunk
        public init(markdown: String) {
            self.markdown = markdown
        }
    }
}

// MARK: - CreateMarkdownV2 Request/Response Models

extension EP.Markdown.CreateMarkdownV2 {

    // MARK: - Request Types

    /// Request body for markdown creation (V2)
    @DTO
    public struct Body {

        // MARK: Properties

        /// Array of text content to convert
        public var texts: [String]

        // MARK: Initialization

        /// Creates a new request body (V2)
        /// - Parameter texts: Array of text content to process
        public init(texts: [String]) {
            self.texts = texts
        }
    }

    // MARK: - Response Types

    /// Response containing complete markdown content
    @DTO
    public struct ResponseContent {

        // MARK: Properties

        /// Generated markdown content
        public var markdown: String

        // MARK: Initialization

        /// Creates a new response content
        /// - Parameter markdown: The complete markdown content
        public init(markdown: String) {
            self.markdown = markdown
        }
    }
}
