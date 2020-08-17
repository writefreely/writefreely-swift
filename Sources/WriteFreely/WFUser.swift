import Foundation

public struct WFUser {
    public var token: String
    public var username: String?
    public var email: String?
    public var createdDate: Date?
}

extension WFUser: Decodable {
    enum RootKeys: String, CodingKey {
        case data
    }

    enum DataKeys: String, CodingKey {
        case token = "access_token"
        case user = "user"
    }

    enum UserKeys: String, CodingKey {
        case username
        case email
        case createdDate = "created"
    }

    /// Creates a `WFUser` object from the server response.
    ///
    ///  Primarily used by the `WFClient` to create a `WFUser` object from the JSON returned by the server.
    ///
    /// - Parameter decoder: The decoder to use for translating the server response to a Swift object.
    /// - Throws: Error thrown by the `try` attempt when decoding any given property.
    public init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootKeys.self)

        let dataContainer = try rootContainer.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        token = try dataContainer.decode(String.self, forKey: .token)

        let userContainer = try dataContainer.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        username = try userContainer.decode(String.self, forKey: .username)
        email = try userContainer.decode(String.self, forKey: .email)
        createdDate = try userContainer.decode(Date.self, forKey: .createdDate)
    }
}
