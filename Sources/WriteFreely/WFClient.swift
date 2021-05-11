import Foundation

// MARK: - URLSession-related protocols

/// Define requirements for `URLSession`s here for dependency-injection purposes (specifically, for testing).
public protocol URLSessionProtocol {
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

/// Define requirements for `URLSessionDataTask`s here for dependency-injection purposes (specifically, for testing).
public protocol URLSessionDataTaskProtocol {
    func resume()
}

// MARK: - Class definition

public class WFClient {
    let decoder: JSONDecoder
    let session: URLSessionProtocol

    public var requestURL: URL
    public var user: WFUser?

    /// Initializes the WriteFreely client.
    ///
    /// Required for connecting to the API endpoints of a WriteFreely instance.
    ///
    /// - Parameters:
    ///   - instanceURL: The URL for the WriteFreely instance to which we're connecting, including the protocol.
    ///   - session: The URL session to use for connections; defaults to `URLSession.shared`.
    public init(for instanceURL: URL, with session: URLSessionProtocol = URLSession.shared) {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.session = session

        // TODO: - Check that the protocol for instanceURL is HTTPS
        requestURL = URL(string: "api/", relativeTo: instanceURL) ?? instanceURL
    }

    // MARK: - Collection-related methods

    /// Creates a new collection.
    ///
    /// If only a `title` is given, the server will generate and return an alias; in this case, clients should store
    /// the returned `alias` for future operations.
    ///
    /// - Parameters:
    ///   - token: The access token for the user creating the collection.
    ///   - title: The title of the new collection.
    ///   - alias: The alias of the collection.
    ///   - completion: A handler for the returned `WFCollection` on success, or `Error` on failure.
    public func createCollection(
        token: String? = nil,
        withTitle title: String,
        alias: String? = nil,
        completion: @escaping (Result<WFCollection, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "collections", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        var bodyObject: [String: Any]
        if let alias = alias {
            bodyObject = [
                "alias": alias,
                "title": title
            ]
        } else {
            bodyObject = [
                "title": title
            ]
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } catch {
            completion(.failure(error))
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 201 CREATED, return the WFCollection as success; if not, return a WFError as failure.
                if response.statusCode == 201 {
                    do {
                        let collection = try self.decoder.decode(ServerData<WFCollection>.self, from: data)

                        completion(.success(collection.data))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    // We didn't get a 200 OK, so return a WFError
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }

    /// Retrieves a collection's metadata.
    ///
    /// Collections can be retrieved without authentication. However, authentication is required for retrieving a
    /// private collection or one with scheduled posts.
    ///
    /// - Parameters:
    ///   - token: The access token for the user retrieving the collection.
    ///   - alias: The alias for the collection to be retrieved.
    ///   - completion: A handler for the returned `WFCollection` on success, or `Error` on failure.
    public func getCollection(
        token: String? = nil,
        withAlias alias: String,
        completion: @escaping (Result<WFCollection, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "collections/\(alias)", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        get(with: request) { result in
            switch result {
            case .success(let data):
                do {
                    let collection = try self.decoder.decode(ServerData<WFCollection>.self, from: data)
                    completion(.success(collection.data))
                } catch {
                    completion(.failure(WFError.invalidData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Permanently deletes a collection.
    ///
    /// Any posts in the collection are not deleted; rather, they are made anonymous.
    ///
    /// - Parameters:
    ///   - token: The access token for the user deleting the collection.
    ///   - alias: The alias for the collection to be deleted.
    ///   - completion: A hander for the returned `Bool` on success, or `Error` on failure.
    public func deleteCollection(
        token: String? = nil,
        withAlias alias: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "collections/\(alias)", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "DELETE"
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                // ⚠️ HACK: There's something that URLSession doesn't like about 204 NO CONTENT response that the API
                //          server is returning. If we get back a "protocol error", the operation probably succeeded,
                //          but URLSession is being pedantic/cranky and throwing an NSPOSIXErrorDomain error code 100.
                //          Here, we check for that error, make sure the token was invalidated, and only then fire the
                //          success case in the completion block.
                let nsError = error as NSError
                if nsError.code == 100 && nsError.domain == NSPOSIXErrorDomain {
                    // Confirm that the operation succeeded by testing for a 404 on the same token.
                    self.deleteCollection(withAlias: alias) { result in
                        do {
                            _ = try result.get()
                            completion(.failure(error))
                        } catch WFError.notFound {
                            completion(.success(true))
                        } catch WFError.unauthorized {
                            completion(.success(true))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.failure(error))
                }
            }

            if let response = response as? HTTPURLResponse {
                // We got a response. If it's a 204 NO CONTENT, return true as success;
                // if not, return a WFError as failure.
                if response.statusCode != 204 {
                    guard let data = data else { return }
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        }

        dataTask.resume()
    }

    // MARK: - Post-related methods

    /// Retrieves an array of posts.
    ///
    /// If the `collectionAlias` argument is provided, an array of all posts in that collection is retrieved; if
    /// omitted, an array of all posts created by the user whose access token is provided is retrieved.
    ///
    /// Collection posts can be retrieved without authentication; however, authentication is required for retrieving a
    /// private collection or one with scheduled posts.
    ///
    /// - Parameters:
    ///   - token: The access token for the user retrieving the posts.
    ///   - collectionAlias: The alias for the collection whose posts are to be retrieved.
    ///   - completion: A handler for the returned `[WFPost]` on success, or `Error` on failure.
    public func getPosts(
        token: String? = nil,
        in collectionAlias: String? = nil,
        completion: @escaping (Result<[WFPost], Error>) -> Void
    ) {
        if token == nil && user == nil { return }

        guard let tokenToVerify = token ?? user?.token else { return }

        var path = ""
        if let alias = collectionAlias {
            // TODO: - Check here that the collection alias exists.
            path = "collections/\(alias)/posts"
        } else {
            path = "me/posts"
        }
        guard let url = URL(string: path, relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        get(with: request) { result in
            switch result {
            case .success(let data):
                do {
                    // The response is formatted differently depending on if we're getting user posts or collection
                    // posts,so we need to determine what kind of structure we're decoding based on the
                    // collectionAlias argument.
                    if collectionAlias != nil {
                        let post = try self.decoder.decode(NestedPostsJson.self, from: data)
                        completion(.success(post.data))
                    } else {
                        let post = try self.decoder.decode(ServerData<[WFPost]>.self, from: data)
                        completion(.success(post.data))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Moves a post to a collection.
    ///
    /// - Attention: ⚠️ **INCOMPLETE IMPLEMENTATION** ⚠️
    ///     - The closure should return a result type of `<[WFPost], Error>`.
    ///     - The modifyToken for the post is currently ignored.
    ///
    /// - Parameters:
    ///   - token: The access token for the user moving the post to a collection.
    ///   - postId: The ID of the post to add to the collection.
    ///   - modifyToken: The post's modify token; required if the post doesn't belong to the requesting user. If `collectionAlias` is `nil`, do not include a `modifyToken`.
    ///   - collectionAlias: The alias of the collection to which the post should be added; if `nil`, this removes the post from any collection.
    ///   - completion: A handler for the returned `Bool` on success, or `Error` on failure.
    public func movePost(
        token: String? = nil,
        postId: String,
        with modifyToken: String? = nil,
        to collectionAlias: String?,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        if collectionAlias == nil && modifyToken != nil { completion(.failure(WFError.badRequest)) }

        var urlString = ""
        if let collectionAlias = collectionAlias {
            urlString = "collections/\(collectionAlias)/collect"
        } else {
            urlString = "posts/disperse"
        }
        guard let url = URL(string: urlString, relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        var bodyObject: [Any]
        if let modifyToken = modifyToken {
            bodyObject = [ [ "id": postId, "token": modifyToken ] ]
        } else {
            bodyObject = collectionAlias == nil ? [ postId ] : [ [ "id": postId ] ]
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } catch {
            completion(.failure(error))
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 200 OK, return true as success; if not, return a WFError as failure.
                if response.statusCode == 200 {
                    completion(.success(true))
                } else {
                    // We didn't get a 200 OK, so return a WFError
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }

    /// Pins a post to a collection.
    ///
    /// Pinning a post to a collection adds it as a navigation item in the collection/blog home page header, rather
    /// than on the blog itself. While the API endpoint can take an array of posts, this function only accepts a single
    /// post.
    ///
    /// - Parameters:
    ///   - token: The access token of the user pinning the post to the collection.
    ///   - postId: The ID of the post to be pinned.
    ///   - position: The numeric position in which to pin the post; if `nil`, will pin at the end of the list.
    ///   - collectionAlias: The alias of the collection to which the post should be pinned.
    ///   - completion: A handler for the `Bool` returned on success, or `Error` on failure.
    public func pinPost(
        token: String? = nil,
        postId: String,
        at position: Int? = nil,
        in collectionAlias: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "collections/\(collectionAlias)/pin", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        var bodyObject: [[String: Any]]
        if let position = position {
            bodyObject = [
                [
                    "id": postId,
                    "position": position
                ]
            ]
        } else {
            bodyObject = [
                [
                    "id": postId
                ]
            ]
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } catch {
            completion(.failure(error))
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 200 OK, return the WFUser as success; if not, return a WFError as failure.
                if response.statusCode == 200 {
                    completion(.success(true))
                } else {
                    // We didn't get a 200 OK, so return a WFError
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }

    /// Unpins a post from a collection.
    ///
    /// Removes the post from a navigation item and puts it back on the blog itself. While the API endpoint can take an
    /// array of posts, this function only accepts a single post.
    ///
    /// - Parameters:
    ///   - token: The access token of the user un-pinning the post from the collection.
    ///   - postId: The ID of the post to be un-pinned.
    ///   - collectionAlias: The alias of the collection to which the post should be un-pinned.
    ///   - completion: A handler for the `Bool` returned on success, or `Error` on failure.
    public func unpinPost(
        token: String? = nil,
        postId: String,
        from collectionAlias: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "collections/\(collectionAlias)/unpin", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        let bodyObject: [[String: Any]] = [
            [
                "id": postId
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } catch {
            completion(.failure(error))
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 200 OK, return the WFUser as success; if not, return a WFError as failure.
                if response.statusCode == 200 {
                    completion(.success(true))
                } else {
                    // We didn't get a 200 OK, so return a WFError
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }

    /// Creates a new post.
    ///
    /// Creates a new post. If a `collectionAlias` is provided, the post is published to that collection; otherwise, it
    /// is posted to the user's Drafts.
    ///
    /// - Parameters:
    ///   - token: The access token of the user creating the post.
    ///   - post: The `WFPost` object to be published.
    ///   - collectionAlias: The collection to which the post should be published.
    ///   - completion: A handler for the `WFPost` object returned on success, or `Error` on failure.
    public func createPost(
        token: String? = nil,
        post: WFPost,
        in collectionAlias: String? = nil,
        completion: @escaping (Result<WFPost, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        var path = ""
        if let alias = collectionAlias {
            // TODO: Check here that the collection alias exists.
            path = "collections/\(alias)/posts"
        } else {
            path = "posts"
        }
        guard let url = URL(string: path, relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        var createdDateString = ""
        if let createdDate = post.createdDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = .withInternetDateTime
            createdDateString = dateFormatter.string(from: createdDate)
        }

        let bodyObject: [String: Any] = [
            "body": post.body,
            "title": post.title ?? "",
            "font": post.appearance ?? "",
            "lang": post.language ?? "",
            "rtl": post.rtl ?? false,
            "created": createdDateString
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } catch {
            completion(.failure(error))
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 200 OK, return the WFPost as success; if not, return a WFError as failure.
                if response.statusCode == 201 {
                    do {
                        let post = try self.decoder.decode(ServerData<WFPost>.self, from: data)

                        completion(.success(post.data))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    // We didn't get a 200 OK, so return a WFError
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }

    /// Retrieves a post.
    ///
    /// The `WFPost` object returned may include additional data, including page views and extracted tags.
    ///
    /// - Parameters:
    ///   - token: The access token of the user retrieving the post.
    ///   - postId: The ID of the post to be retrieved.
    ///   - completion: A handler for the `WFPost` object returned on success, or `Error` on failure.
    public func getPost(
        token: String? = nil,
        byId postId: String,
        completion: @escaping (Result<WFPost, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "posts/\(postId)", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        get(with: request) { result in
            switch result {
            case .success(let data):
                do {
                    let post = try self.decoder.decode(ServerData<WFPost>.self, from: data)
                    completion(.success(post.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Retrieves a post from a collection.
    ///
    /// Collection posts can be retrieved without authentication. However, authentication is required for retrieving a
    /// post from a private collection.
    ///
    /// The `WFPost` object returned may include additional data, including page views and extracted tags.
    ///
    /// - Parameters:
    ///   - token: The access token of the user retrieving the post.
    ///   - slug: The slug of the post to be retrieved.
    ///   - collectionAlias: The alias of the collection from which the post should be retrieved.
    ///   - completion: A handler for the `WFPost` object returned on success, or `Error` on failure.
    public func getPost(
        token: String? = nil,
        bySlug slug: String,
        from collectionAlias: String,
        completion: @escaping (Result<WFPost, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "collections/\(collectionAlias)/posts/\(slug)", relativeTo: requestURL) else {
            return
        }
        var request = URLRequest(url: url)
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        get(with: request) { result in
            switch result {
            case .success(let data):
                do {
                    let post = try self.decoder.decode(ServerData<WFPost>.self, from: data)
                    completion(.success(post.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing post.
    ///
    /// Note that if the `updatedPost` object is provided without a title, the original post's title will be removed.
    ///
    /// - Attention: ⚠️ INCOMPLETE IMPLEMENTATION⚠️
    ///     - The modifyToken for the post is currently ignored.
    ///
    /// - Parameters:
    ///   - token: The access token for the user updating the post.
    ///   - postId: The ID of the post to be updated.
    ///   - updatedPost: The `WFPost` object with which to update the existing post.
    ///   - modifyToken: The post's modify token; required if the post doesn't belong to the requesting user.
    ///   - completion: A handler for the `WFPost` object returned on success, or `Error` on failure.
    public func updatePost(
        token: String? = nil,
        postId: String,
        updatedPost: WFPost,
        with modifyToken: String? = nil,
        completion: @escaping (Result<WFPost, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "posts/\(postId)", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        let bodyObject: [String: Any] = [
            "body": updatedPost.body,
            "title": updatedPost.title ?? "",
            "font": updatedPost.appearance ?? "",
            "lang": updatedPost.language ?? "",
            "rtl": updatedPost.rtl ?? false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } catch {
            completion(.failure(error))
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 200 OK, return the WFPost as success; if not, return a WFError as failure.
                if response.statusCode == 200 {
                    do {
                        let post = try self.decoder.decode(ServerData<WFPost>.self, from: data)

                        completion(.success(post.data))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    // We didn't get a 200 OK, so return a WFError
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }

    /// Deletes an existing post.
    ///
    /// - Attention: ⚠️ INCOMPLETE IMPLEMENTATION⚠️
    ///     - The modifyToken for the post is currently ignored.
    ///
    /// - Parameters:
    ///   - token: The access token for the user deleting the post.
    ///   - postId: The ID of the post to be deleted.
    ///   - modifyToken: The post's modify token; required if the post doesn't belong to the requesting user.
    ///   - completion: A handler for the `Bool` object returned on success, or `Error` on failure.
    public func deletePost(
        token: String? = nil,
        postId: String,
        with modifyToken: String? = nil,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        if token == nil && user == nil { return }
        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "posts/\(postId)", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "DELETE"
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                // ⚠️ HACK: There's something that URLSession doesn't like about 204 NO CONTENT response that the API
                //          server is returning. If we get back a "protocol error", the operation probably succeeded,
                //          but URLSession is being pedantic/cranky and throwing an NSPOSIXErrorDomain error code 100.
                //          Here, we check for that error, make sure the token was invalidated, and only then fire the
                //          success case in the completion block.
                let nsError = error as NSError
                if nsError.code == 100 && nsError.domain == NSPOSIXErrorDomain {
                    // Confirm that the operation succeeded by testing for a 404 on the same token.
                    self.deletePost(postId: postId) { result in
                        do {
                            _ = try result.get()
                            completion(.failure(error))
                        } catch WFError.notFound {
                            completion(.success(true))
                        } catch WFError.unauthorized {
                            completion(.success(true))
                        } catch WFError.internalServerError {
                            // If you try to delete a non-existent post, the API returns a 500 Internal Server Error.
                            completion(.success(true))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.failure(error))
                }
            }

            if let response = response as? HTTPURLResponse {
                // We got a response. If it's a 204 NO CONTENT, return true as success;
                // if not, return a WFError as failure.
                if response.statusCode != 204 {
                    guard let data = data else { return }
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        }

        dataTask.resume()
    }

    /* Placeholder method stub: API design for this feature is not yet finalized.
    func unpublishPost() {}
     */

    /* Placeholder method stub: this feature is not yet implemented (Write.as feature only).
    func claimPost() {}
     */

    // MARK: - User-related methods

    /// Logs the user in to their account on the WriteFreely instance.
    ///
    /// On successful login, the `WFClient`'s `user` property is set to the returned `WFUser` object; this allows
    /// authenticated requests to be made without having to provide an access token.
    ///
    /// It is otherwise not necessary to login the user if their access token is provided to the calling function.
    ///
    /// - Parameters:
    ///   - username: The user's username.
    ///   - password: The user's password.
    ///   - completion: A handler for the `WFUser` object returned on success, or `Error` on failure.
    public func login(username: String, password: String, completion: @escaping (Result<WFUser, Error>) -> Void) {
        guard let url = URL(string: "auth/login", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let bodyObject: [String: Any] = [
            "alias": username,
            "pass": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
        } catch {
            completion(.failure(error))
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 200 OK, return the WFUser as success; if not, return a WFError as failure.
                if response.statusCode == 200 {
                    do {
                        let user = try self.decoder.decode(WFUser.self, from: data)
                        self.user = user
                        completion(.success(user))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    // We didn't get a 200 OK, so return a WFError
                    guard let error = self.translateWFError(fromServerResponse: data) else {
                        // We couldn't generate a WFError from the server response data, so return an unknown error.
                        completion(.failure(WFError.unknownError))
                        return
                    }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }

    /// Invalidates the user's access token.
    ///
    /// - Parameters:
    ///   - token: The token to invalidate.
    ///   - completion: A handler for the `Bool` object returned on success, or `Error` on failure.
    public func logout(token: String? = nil, completion: @escaping (Result<Bool, Error>) -> Void) {
        if token == nil && user == nil { return }

        guard let tokenToDelete = token ?? user?.token else { return }

        guard let url = URL(string: "auth/me", relativeTo: requestURL) else { fatalError() }
        var request = URLRequest(url: url)

        request.httpMethod = "DELETE"
        request.addValue(tokenToDelete, forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                // ⚠️ HACK: There's something that URLSession doesn't like about 204 NO CONTENT response that the API
                //          server is returning. If we get back a "protocol error", the operation probably succeeded,
                //          but URLSession is being pedantic/cranky and throwing an NSPOSIXErrorDomain error code 100.
                //          Here, we check for that error, make sure the token was invalidated, and only then fire the
                //          success case in the completion block.
                let nsError = error as NSError
                if nsError.code == 100 && nsError.domain == NSPOSIXErrorDomain {
                    // Confirm that the operation succeeded by testing for a 404 on the same token.
                    self.logout(token: tokenToDelete) { result in
                        do {
                            _ = try result.get()
                            completion(.failure(error))
                        } catch WFError.notFound {
                            self.user = nil
                            completion(.success(true))
                        } catch WFError.unauthorized {
                            self.user = nil
                            completion(.success(true))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.failure(error))
                }
            }

            if let response = response as? HTTPURLResponse {
                // We got a response. If it's a 204 NO CONTENT, return true as success;
                // if not, return a WFError as failure.
                if response.statusCode != 204 {
                    guard let data = data else { return }
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                } else {
                    self.user = nil
                    completion(.success(true))
                }
            }
        }

        dataTask.resume()
    }

    /// Retrieves a user's basic data.
    ///
    /// - Parameters:
    ///   - token: The access token for the user to fetch.
    ///   - completion: A handler for the `Data` object returned on success, or `Error` on failure.
    public func getUserData(token: String? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        if token == nil && user == nil { return }

        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "me", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        get(with: request) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Retrieves a user's collections.
    ///
    /// - Parameters:
    ///   - token: The access token for the user whose collections are to be retrieved.
    ///   - completion: A handler for the `[WFCollection]` object returned on success, or `Error` on failure.
    public func getUserCollections(token: String? = nil, completion: @escaping (Result<[WFCollection], Error>) -> Void) {
        if token == nil && user == nil { return }

        guard let tokenToVerify = token ?? user?.token else { return }

        guard let url = URL(string: "me/collections", relativeTo: requestURL) else { return }
        var request = URLRequest(url: url)

        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(tokenToVerify, forHTTPHeaderField: "Authorization")

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            // Something went wrong; return the error message.
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                guard let data = data else { return }

                // If we get a 200 OK, return the WFUser as success; if not, return a WFError as failure.
                if response.statusCode == 200 {
                    do {
                        let collection = try self.decoder.decode(ServerData<[WFCollection]>.self, from: data)
                        completion(.success(collection.data))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    // We didn't get a 200 OK, so return a WFError.
                    guard let error = self.translateWFError(fromServerResponse: data) else { return }
                    completion(.failure(error))
                }
            }
        }

        dataTask.resume()
    }
}

private extension WFClient {
    func translateWFError(fromServerResponse response: Data) -> WFError? {
        do {
            let error = try self.decoder.decode(ErrorMessage.self, from: response)
            print("⛔️ \(error.message)")
            return WFError(rawValue: error.code)
        } catch {
            print("⛔️ An unknown error occurred.")
            return WFError.unknownError
        }
    }
}

// MARK: - Protocol conformance

extension URLSession: URLSessionProtocol {
    public func dataTask(
        with request: URLRequest,
        completionHandler: @escaping DataTaskResult
    ) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}
