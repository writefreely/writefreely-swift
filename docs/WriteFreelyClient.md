# WriteFreelyClient

``` swift
public class WriteFreelyClient
```

## Initializers

### `init(for:)`

Initializes the WriteFreelyClient.

``` swift
public init(for instanceURL: URL)
```

Required for connecting to the API endpoints of a WriteFreely instance.

#### Parameters

  - instanceURL: - instanceURL: The URL for the WriteFreely instance to which we're connecting, including the protocol.

## Properties

### `decoder`

``` swift
let decoder
```

### `requestURL`

``` swift
var requestURL: URL
```

### `user`

``` swift
var user: User?
```

## Methods

### `createCollection(token:withTitle:alias:completion:)`

Creates a new collection.

``` swift
public func createCollection(token: String? = nil, withTitle title: String, alias: String? = nil, completion: @escaping (Result<Collection, Error>) -> Void)
```

If only a `title` is given, the server will generate and return an alias; in this case, clients should store
the returned `alias` for future operations.

#### Parameters

  - token: - token: The access token for the user creating the collection.
  - title: - title: The title of the new collection.
  - alias: - alias: The alias of the collection.
  - completion: - completion: A handler for the returned `Collection` on success, or `Error` on failure.

### `getCollection(token:withAlias:completion:)`

Retrieves a collection's metadata.

``` swift
public func getCollection(token: String? = nil, withAlias alias: String, completion: @escaping (Result<Collection, Error>) -> Void)
```

Collections can be retrieved without authentication. However, authentication is required for retrieving a
private collection or one with scheduled posts.

#### Parameters

  - token: - token: The access token for the user retrieving the collection.
  - alias: - alias: The alias for the collection to be retrieved.
  - completion: - completion: A handler for the returned `Collection` on success, or `Error` on failure.

### `deleteCollection(token:withAlias:completion:)`

Permanently deletes a collection.

``` swift
public func deleteCollection(token: String? = nil, withAlias alias: String, completion: @escaping (Result<Bool, Error>) -> Void)
```

Any posts in the collection are not deleted; rather, they are made anonymous.

#### Parameters

  - token: - token: The access token for the user deleting the collection.
  - alias: - alias: The alias for the collection to be deleted.
  - completion: - completion: A hander for the returned `Bool` on success, or `Error` on failure.

### `getPosts(token:in:completion:)`

Retrieves an array of posts.

``` swift
public func getPosts(token: String? = nil, in collectionAlias: String? = nil, completion: @escaping (Result<[Post], Error>) -> Void)
```

If the `collectionAlias` argument is provided, an array of all posts in that collection is retrieved; if
omitted, an array of all posts created by the user whose access token is provided is retrieved.

Collection posts can be retrieved without authentication; however, authentication is required for retrieving a
private collection or one with scheduled posts.

#### Parameters

  - token: - token: The access token for the user retrieving the posts.
  - collectionAlias: - collectionAlias: The alias for the collection whose posts are to be retrieved.
  - completion: - completion: A handler for the returned `[Post]` on success, or `Error` on failure.

### `movePost(token:postId:with:to:completion:)`

Moves a post to a collection.

``` swift
public func movePost(token: String? = nil, postId: String, with modifyToken: String? = nil, to collectionAlias: String, completion: @escaping (Result<Bool, Error>) -> Void)
```

> Attention:   - The closure should return a result type of \`\<\[Post\], Error\>\`.
>   - The modifyToken for the post is currently ignored.
>   

#### Parameters

  - token: - token: The access token for the user moving the post to a collection.
  - postId: - postId: The ID of the post to add to the collection.
  - modifyToken: - modifyToken: The post's modify token; required if the post doesn't belong to the requesting user.
  - collectionAlias: - collectionAlias: The alias of the collection to which the post should be added.
  - completion: - completion: A handler for the returned `Bool` on success, or `Error` on failure.

### `pinPost(token:postId:at:in:completion:)`

Pins a post to a collection.

``` swift
public func pinPost(token: String? = nil, postId: String, at position: Int? = nil, in collectionAlias: String, completion: @escaping (Result<Bool, Error>) -> Void)
```

Pinning a post to a collection adds it as a navigation item in the collection/blog home page header, rather
than on the blog itself. While the API endpoint can take an array of posts, this function only accepts a single
post.

#### Parameters

  - token: - token: The access token of the user pinning the post to the collection.
  - postId: - postId: The ID of the post to be pinned.
  - position: - position: The numeric position in which to pin the post; if `nil`, will pin at the end of the list.
  - collectionAlias: - collectionAlias: The alias of the collection to which the post should be pinned.
  - completion: - completion: A handler for the `Bool` returned on success, or `Error` on failure.

### `unpinPost(token:postId:from:completion:)`

Unpins a post from a collection.

``` swift
public func unpinPost(token: String? = nil, postId: String, from collectionAlias: String, completion: @escaping (Result<Bool, Error>) -> Void)
```

Removes the post from a navigation item and puts it back on the blog itself. While the API endpoint can take an
array of posts, this function only accepts a single post.

#### Parameters

  - token: - token: The access token of the user un-pinning the post from the collection.
  - postId: - postId: The ID of the post to be un-pinned.
  - collectionAlias: - collectionAlias: The alias of the collection to which the post should be un-pinned.
  - completion: - completion: A handler for the `Bool` returned on success, or `Error` on failure.

### `createPost(token:post:in:completion:)`

Creates a new post.

``` swift
public func createPost(token: String? = nil, post: Post, in collectionAlias: String? = nil, completion: @escaping (Result<Post, Error>) -> Void)
```

Creates a new post. If a `collectionAlias` is provided, the post is published to that collection; otherwise, it
is posted to the user's Drafts.

#### Parameters

  - token: - token: The access token of the user creating the post.
  - post: - post: The `Post` object to be published.
  - collectionAlias: - collectionAlias: The collection to which the post should be published.
  - completion: - completion: A handler for the `Post` object returned on success, or `Error` on failure.

### `getPost(token:byId:completion:)`

Retrieves a post.

``` swift
public func getPost(token: String? = nil, byId postId: String, completion: @escaping (Result<Post, Error>) -> Void)
```

The `Post` object returned may include additional data, including page views and extracted tags.

#### Parameters

  - token: - token: The access token of the user retrieving the post.
  - postId: - postId: The ID of the post to be retrieved.
  - completion: - completion: A handler for the `Post` object returned on success, or `Error` on failure.

### `getPost(token:bySlug:from:completion:)`

Retrieves a post from a collection.

``` swift
public func getPost(token: String? = nil, bySlug slug: String, from collectionAlias: String, completion: @escaping (Result<Post, Error>) -> Void)
```

Collection posts can be retrieved without authentication. However, authentication is required for retrieving a
post from a private collection.

The `Post` object returned may include additional data, including page views and extracted tags.

#### Parameters

  - token: - token: The access token of the user retrieving the post.
  - slug: - slug: The slug of the post to be retrieved.
  - collectionAlias: - collectionAlias: The alias of the collection from which the post should be retrieved.
  - completion: - completion: A handler for the `Post` object returned on success, or `Error` on failure.

### `updatePost(token:postId:updatedPost:with:completion:)`

Updates an existing post.

``` swift
public func updatePost(token: String? = nil, postId: String, updatedPost: Post, with modifyToken: String? = nil, completion: @escaping (Result<Post, Error>) -> Void)
```

Note that if the `updatedPost` object is provided without a title, the original post's title will be removed.

> Attention:   - The modifyToken for the post is currently ignored.
>   

#### Parameters

  - token: - token: The access token for the user updating the post.
  - postId: - postId: The ID of the post to be updated.
  - updatedPost: - updatedPost: The `Post` object with which to update the existing post.
  - modifyToken: - modifyToken: The post's modify token; required if the post doesn't belong to the requesting user.
  - completion: - completion: A handler for the `Post` object returned on success, or `Error` on failure.

### `deletePost(token:postId:with:completion:)`

Deletes an existing post.

``` swift
public func deletePost(token: String? = nil, postId: String, with modifyToken: String? = nil, completion: @escaping (Result<Bool, Error>) -> Void)
```

> Attention:   - The modifyToken for the post is currently ignored.
>   

#### Parameters

  - token: - token: The access token for the user deleting the post.
  - postId: - postId: The ID of the post to be deleted.
  - modifyToken: - modifyToken: The post's modify token; required if the post doesn't belong to the requesting user.
  - completion: - completion: A handler for the `Bool` object returned on success, or `Error` on failure.

### `login(username:password:completion:)`

Logs the user in to their account on the WriteFreely instance.

``` swift
public func login(username: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
```

On successful login, the `WriteFreelyClient`'s `user` property is set to the returned `User` object; this allows
authenticated requests to be made without having to provide an access token.

It is otherwise not necessary to login the user if their access token is provided to the calling function.

#### Parameters

  - username: - username: The user's username.
  - password: - password: The user's password.
  - completion: - completion: A handler for the `User` object returned on success, or `Error` on failure.

### `logout(token:completion:)`

Invalidates the user's access token.

``` swift
public func logout(token: String? = nil, completion: @escaping (Result<Bool, Error>) -> Void)
```

#### Parameters

  - token: - token: The token to invalidate.
  - completion: - completion: A handler for the `Bool` object returned on success, or `Error` on failure.

### `getUserData(token:completion:)`

Retrieves a user's basic data.

``` swift
public func getUserData(token: String? = nil, completion: @escaping (Result<Data, Error>) -> Void)
```

#### Parameters

  - token: - token: The access token for the user to fetch.
  - completion: - completion: A handler for the `Data` object returned on success, or `Error` on failure.

### `getUserCollections(token:completion:)`

Retrieves a user's collections.

``` swift
public func getUserCollections(token: String? = nil, completion: @escaping (Result<[Collection], Error>) -> Void)
```

#### Parameters

  - token: - token: The access token for the user whose collections are to be retrieved.
  - completion: - completion: A handler for the `[Collection]` object returned on success, or `Error` on failure.

### `translateWriteFreelyError(fromServerResponse:)`

``` swift
func translateWriteFreelyError(fromServerResponse response: Data) -> WriteFreelyError?
```
