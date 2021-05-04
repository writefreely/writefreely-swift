import Foundation

public enum WFError: Int, Error {
    // Errors returned by the server
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case gone = 410
    case preconditionFailed = 412
    case tooManyRequests = 429
    case internalServerError = 500
    case badGateway = 502
    case serviceUnavailable = 503

    // Other errors
    case unknownError = -1
    case couldNotComplete = -2
    case invalidResponse = -3
    case invalidData = -4
}

struct ErrorMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case code
        case message = "error_msg"
    }

    let code: Int
    let message: String
}
