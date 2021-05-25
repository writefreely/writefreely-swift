import Foundation

extension WFClient {

    /// Sends a `GET` request.
    /// - Parameters:
    ///   - request: The `URLRequest` for the `GET` request
    ///   - completion: A closure that captures a `Result` with a `Data` object on success, or a `WFError` on failure.
    func get(with request: URLRequest, completion: @escaping (Result<Data, WFError>) -> Void) {
        if request.httpMethod != "GET" {
            preconditionFailure("Expected GET request, but got \(request.httpMethod ?? "nil")")
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(.failure(.couldNotComplete))
                return
            }

            guard let unwrappedResponse = response as? HTTPURLResponse, unwrappedResponse.statusCode == 200 else {
                if let response = response as? HTTPURLResponse {
                    completion(.failure(WFError(rawValue: response.statusCode) ?? .invalidResponse))
                } else {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }

            completion(.success(data))
        }

        dataTask.resume()
    }

    /// Sends a `POST` request.
    /// - Parameters:
    ///   - request: The `URLRequest` for the `POST` request
    ///   - expecting: The status code expected to be returned by the server
    ///   - completion: A closure that captures a `Result` with a `Data` object on success, or a `WFError` on failure.
    func post(
        with request: URLRequest,
        expecting statusCode: Int,
        completion: @escaping (Result<Data, WFError>) -> Void
    ) {
        if request.httpMethod != "POST" {
            preconditionFailure("Expected POST request, but got \(request.httpMethod ?? "nil")")
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(.failure(.couldNotComplete))
                return
            }

            guard let unwrappedResponse = response as? HTTPURLResponse, unwrappedResponse.statusCode == statusCode else {
                if let response = response as? HTTPURLResponse {
                    completion(.failure(WFError(rawValue: response.statusCode) ?? .invalidResponse))
                } else {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }

            completion(.success(data))
        }

        dataTask.resume()
    }

    /// Sends a `DELETE` request.
    /// - Parameters:
    ///   - request: The `URLRequest` for the `DELETE` request
    ///   - completion: A closure that captures a `Result` with a `Data` object on success, or a `WFError` on failure.
    func delete(with request: URLRequest, completion: @escaping (Result<Data, WFError>) -> Void) {
        if request.httpMethod != "DELETE" {
            preconditionFailure("Expected DELETE request, but got \(request.httpMethod ?? "nil")")
        }

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(.failure(.couldNotComplete))
                return
            }

            guard let unwrappedResponse = response as? HTTPURLResponse, unwrappedResponse.statusCode == 204 else {
                if let response = response as? HTTPURLResponse {
                    completion(.failure(WFError(rawValue: response.statusCode) ?? .invalidResponse))
                } else {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }

            completion(.success(data))
        }

        dataTask.resume()
    }
}
