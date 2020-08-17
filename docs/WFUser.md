# WFUser

``` swift
public struct WFUser
```

## Inheritance

`Decodable`

## Initializers

### `init(from:)`

Creates a `WFUser` object from the server response.

``` swift
public init(from decoder: Decoder) throws
```

Primarily used by the `WFClient` to create a `WFUser` object from the JSON returned by the server.

#### Parameters

  - decoder: - decoder: The decoder to use for translating the server response to a Swift object.

#### Throws

Error thrown by the `try` attempt when decoding any given property.

## Properties

### `token`

``` swift
var token: String
```

### `username`

``` swift
var username: String?
```

### `email`

``` swift
var email: String?
```

### `createdDate`

``` swift
var createdDate: Date?
```
