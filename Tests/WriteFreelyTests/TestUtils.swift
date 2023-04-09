import Foundation
import WriteFreely

final class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private (set) var resumeWasCalled = false

    func resume() {
        resumeWasCalled = true
    }
}

final class MockURLSession: URLSessionProtocol {
    var nextDataTask = MockURLSessionDataTask()
    var nextData: Data?
    var nextError: Error?
    var expectedStatusCode: Int = 200

    private (set) var lastRequest: URLRequest?

    func successURLResponse(url: URL) -> URLResponse {
        return HTTPURLResponse(
            url: url,
            statusCode: expectedStatusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        lastRequest = request
        completionHandler(
            nextData,
            successURLResponse(url: (request.url ?? URL(string: "https://example.com")!)),
            nextError
        )
        return nextDataTask
    }
}
