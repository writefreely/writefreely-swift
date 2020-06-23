import Foundation

enum WriteFreelyError: Int, Error {
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
}

struct ErrorMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case code
        case message = "error_msg"
    }

    let code: Int
    let message: String
}
