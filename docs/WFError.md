# WFError

``` swift
public enum WFError: Int, Error 
```

## Inheritance

`Error`, `Int`

## Enumeration Cases

### `badRequest`

``` swift
case badRequest = 400
```

### `unauthorized`

``` swift
case unauthorized = 401
```

### `forbidden`

``` swift
case forbidden = 403
```

### `notFound`

``` swift
case notFound = 404
```

### `methodNotAllowed`

``` swift
case methodNotAllowed = 405
```

### `gone`

``` swift
case gone = 410
```

### `preconditionFailed`

``` swift
case preconditionFailed = 412
```

### `tooManyRequests`

``` swift
case tooManyRequests = 429
```

### `internalServerError`

``` swift
case internalServerError = 500
```

### `badGateway`

``` swift
case badGateway = 502
```

### `serviceUnavailable`

``` swift
case serviceUnavailable = 503
```

### `unknownError`

``` swift
case unknownError = -1
```

### `couldNotComplete`

``` swift
case couldNotComplete = -2
```

### `invalidResponse`

``` swift
case invalidResponse = -3
```

### `invalidData`

``` swift
case invalidData = -4
```
