import Foundation
import XCTest
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

    @discardableResult
    func setData(resource: String, fileExt: String, for target: XCTestCase) throws -> URL? {
        guard let fileURL = Bundle.module.url(forResource: resource, withExtension: fileExt) else {
            return nil
        }
        do {
            nextData = try Data(contentsOf: fileURL)
            return fileURL
        } catch {
            throw error
        }
    }
}
