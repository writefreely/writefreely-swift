# URLSessionProtocol

Define requirements for `URLSession`s here for dependency-injection purposes (specifically, for testing).

``` swift
public protocol URLSessionProtocol 
```

## Requirements

### DataTaskResult

``` swift
typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
```

### dataTask(with:​completionHandler:​)

``` swift
func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
```
