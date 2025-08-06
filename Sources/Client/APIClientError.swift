import ErrorKit

// MARK: - APIClientError

/// Enumeration of possible API client errors
///
/// This enum represents all the different types of errors that can occur
/// during API client operations, providing detailed error information
/// and user-friendly messages for each case.
public enum APIClientError: Throwable, Catching {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(message: String)
    case invalidAccessToken
    case urlSessionError(URLSessionError)
    case cancelled
    case caught(_ error: Error)

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
        case .caught(let error):
            ErrorKit.userFriendlyMessage(for: error)
        }
    }
}
