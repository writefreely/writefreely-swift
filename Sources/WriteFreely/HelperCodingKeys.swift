import Foundation

struct ServerData<T: Decodable>: Decodable {
    enum CodingKeys: String, CodingKey {
        case code
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        data = try container.decode(T.self, forKey: .data)
    }

    let code: Int
    let data: T
}

struct NestedPostsJson: Decodable {
    enum CodingKeys: String, CodingKey {
        case code
        case data

        enum PostKeys: String, CodingKey {
            case posts
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let postsContainer = try container.nestedContainer(keyedBy: CodingKeys.PostKeys.self, forKey: .data)
        data = try postsContainer.decode([WFPost].self, forKey: .posts)
    }

    let data: [WFPost]
}
