import ErrorKit
import SwiftAPICore

// MARK: - APIClientError

/// Enumeration of possible API client errors
///
/// This enum represents all the different types of errors that can occur
/// during API client operations, providing detailed error information
/// and user-friendly messages for each case.
public enum APIClientError<EndpointError: CodableError>: Throwable, Catching {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(message: String)
    case invalidAccessToken
    case urlSessionError(URLSessionError)
    case cancelled
    case handledByErrorHandler
    case endpointError(EndpointError)
    case caught(_ error: Error)

    public var isCancelled: Bool {
        if case .cancelled = self {
            return true
        }

        if case .urlSessionError(let urlSessionError) = self,
            case .cancelled = urlSessionError
        {
            return true
        }

        return false
    }

    public var userFriendlyMessage: String {
        switch self {
        case .invalidResponse:
            "Invalid response from server."
        case .invalidAccessToken:
            "Invalid access token."
        case .serverError(let statusCode, let message):
            "Server error with status code: \(statusCode), message: \(message)"
        case .decodingError(let message):
            "Failed to decode response: \(message)"
        case .urlSessionError(let error):
            "\(error.userFriendlyMessage)"
        case .cancelled:
            "The request was cancelled."
        case .handledByErrorHandler:
            ""
        case .endpointError(let error):
            error.localizedDescription
        case .caught(let error):
            ErrorKit.userFriendlyMessage(for: error)
        }
    }
}
