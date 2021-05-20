# WFUser

``` swift
public struct WFUser 
```

## Inheritance

`Decodable`

## Initializers

### `init(token:username:)`

Creates a minimum `WFUser` object from a stored token.

``` swift
public init(token: String, username: String?) 
```

Use this when the client has already logged in a user and only needs to reconstruct the type from saved properties.

#### Parameters

  - token: The user's access token
  - username: The user's username (optional)

### `init(from:)`

Creates a `WFUser` object from the server response.

``` swift
public init(from decoder: Decoder) throws 
```

Primarily used by the `WFClient` to create a `WFUser` object from the JSON returned by the server.

#### Parameters

  - decoder: The decoder to use for translating the server response to a Swift object.

#### Throws

Error thrown by the `try` attempt when decoding any given property.

## Properties

### `token`

``` swift
public var token: String
```

### `username`

``` swift
public var username: String?
```

### `email`

``` swift
public var email: String?
```

### `createdDate`

``` swift
public var createdDate: Date?
```
