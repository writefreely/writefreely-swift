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

    /// Creates a minimum `WFUser` object from a stored token.
    ///
    /// Use this when the client has already logged in a user and only needs to reconstruct the type from saved properties.
    ///
    /// - Parameter token: The user's access token
    /// - Parameter username: The user's username (optional)
    public init(token: String, username: String?) {
        self.token = token
        if let username = username {
            self.username = username
        }
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

extension WFUser {
    static let testUser = WFUser(token: "00000000-0000-0000-0000-000000000000",
                                 username: "matt",
                                 email: "matt@example.com",
                                 createdDate: DateComponents(calendar: .current,
                                                             timeZone: TimeZone(abbreviation: "UTC"),
                                                             year: 2015,
                                                             month: 02,
                                                             day: 03,
                                                             hour: 02,
                                                             minute: 41,
                                                             second: 19
                                                            ).date
    )
}
