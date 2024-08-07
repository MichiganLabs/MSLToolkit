import Alamofire
import Foundation

public enum NetworkAdapterError: Error {
    case missingUrl
}

/// A convenience class for providing dynamic data (such as authentication) to a request
/// that is agnostic of a specific endpoint and required for the API.
open class ApiRequestAdapter: RequestAdapter {
    private let scheme: String?
    private let host: String
    private let authHandler: ((URLRequest) -> URLRequest)?

    public init(scheme: String? = nil, host: String, authHandler: ((URLRequest) -> URLRequest)? = nil) {
        self.scheme = scheme
        self.host = host
        self.authHandler = authHandler
    }

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (
            Result<URLRequest, Error>
        ) -> Void
    ) {
        guard
            let url = urlRequest.url
        else {
            completion(.failure(NetworkAdapterError.missingUrl))
            return
        }

        var components = URLComponents()
        components.scheme = self.scheme
        components.host = self.host
        components.path = url.path
        components.query = url.query
        components.fragment = url.fragment

        var newRequest = urlRequest
        newRequest.url = try? components.asURL()

        if let handler = self.authHandler {
            newRequest = handler(newRequest)
        }

        completion(.success(newRequest))
    }
}
