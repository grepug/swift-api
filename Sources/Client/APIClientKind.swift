//
// Client.swift
// SwiftAPI
//
// Created by Kai Shao on 2025/4/17.
// Copyright © 2025 Organization. All rights reserved.
//

/// API client implementation for handling HTTP requests and streaming responses.
///
/// This file provides the core networking layer for the SwiftAPI framework,
/// including support for both standard HTTP requests and streaming responses.
/// It handles authentication, error management, and data serialization/deserialization.
///
/// - Note: All client operations are designed to be called from the main actor
/// - Since: 1.0.0

// MARK: - System Imports

import ConcurrencyUtils
import ErrorKit
import Foundation
import SwiftAPICore

// MARK: - Third-party Imports

// MARK: - APIClientKind Protocol

/// Protocol defining the core API client functionality
///
/// This protocol establishes the contract for making HTTP requests to API endpoints,
/// handling both standard data requests and streaming responses with proper error handling.
public protocol APIClientKind: Sendable {

    // MARK: - Required Methods

    /// Performs a data request on the specified endpoint
    ///
    /// - Parameter endpoint: The endpoint to make the request to
    /// - Returns: The decoded response content
    /// - Throws: APIClientError for various failure scenarios
    func data<E: Endpoint>(on endpoint: E) async throws(APIClientError) -> E.Content

    /// Creates a streaming connection to the specified endpoint
    ///
    /// - Parameter endpoint: The endpoint to stream from
    /// - Returns: An async throwing stream of response chunks
    func stream<E>(on endpoint: E) -> AsyncThrowingStream<E.Chunk, Error> where E: Endpoint

    /// Performs a generic data request with custom parameters
    ///
    /// - Parameters:
    ///   - path: The API path
    ///   - method: The HTTP method
    ///   - query: The query parameters
    ///   - body: The request body
    ///   - type: The type to decode the response as
    /// - Returns: The decoded response of the specified type
    /// - Throws: APIClientError for various failure scenarios
    func data<T, Body, Query>(
        _ path: String,
        method: EndpointMethod,
        query: Query,
        body: Body,
        decodingAs type: T.Type,
    ) async throws(APIClientError) -> T where T: Codable, Body: Encodable, Query: Encodable

    /// Provides the access token for authentication
    ///
    /// - Returns: The current access token string
    func accessToken() -> String

    /// Creates a streaming connection for the given request
    ///
    /// - Parameter request: The URL request to stream
    /// - Returns: An async throwing stream of string responses
    func makeStream(request: URLRequest) -> AsyncThrowingStream<String, Error>

    // MARK: - Required Properties

    /// The base URL for all API requests
    var baseURL: URL { get }

    func handleServerResponseError(
        statusCode: Int,
        message: String,
        response: URLResponse
    ) async -> Bool
}
