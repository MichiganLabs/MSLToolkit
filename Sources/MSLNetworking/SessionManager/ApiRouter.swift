import Foundation

import Alamofire

/// Create a new enum that implements this protocol to make requests through instances of `ApiRouterRequestable`.
///
/// NOTE: According to the Alamofire guidelines, the object that implements this protocol should only
/// contain static information. All dynamic information should be put into the `RequestAdapter` object.
///
public protocol ApiRouter: URLRequestConvertible {
    /// The HTTP method for a specific endpoint
    var method: HTTPMethod { get }

    /// A convenient way to specify the path for a specific endpoint
    ///
    /// This should NOT include the scheme or host as that should be specified in the `RequestAdapter`.
    var path: String { get }

    /// The url for a specific endpoint.
    /// The default implementation just converts the path to a `URL` type.
    var url: URL { get }

    var multipartFormData: ((MultipartFormData) -> Void)? { get }

    // Default Values are already implemented. These values can be overridden if desired.
    var timeoutInterval: Double { get }

    /// In the event that there is a specific endpoint that requires slightly different validation than
    /// the rest of the API, this property can be used to override the default request validation.
    ///
    /// In general, this property should be avoided - just build better APIs ;)
    var validationOverride: Alamofire.DataRequest.Validation? { get }

    /// In the event that there is a specific endpoint that requires slightly different error handling
    /// than the rest of the API, this property can be used to override the default error handling.
    ///
    /// In general, this property should be avoided - just build better APIs ;)
    var errorHandlerOverride: ApiSessionManager.ErrorHandler? { get }
}

// Default values
public extension ApiRouter {
    var multipartFormData: ((MultipartFormData) -> Void)? {
        return nil
    }

    var timeoutInterval: Double {
        return 60
    }

    var url: URL {
        // swiftlint:disable:next force_unwrapping
        return URL(string: self.path)!
    }

    var validationOverride: Alamofire.DataRequest.Validation? {
        return nil
    }

    var errorHandlerOverride: ApiSessionManager.ErrorHandler? {
        return nil
    }
}

// Helper properties
public extension ApiRouter {
    /// Builds a request that all requests will have in common
    var defaultRequest: URLRequest {
        var urlRequest = URLRequest(url: self.url)
        urlRequest.httpMethod = self.method.rawValue
        urlRequest.timeoutInterval = self.timeoutInterval

        var headers: HTTPHeaders = [:]

        if [.post, .put, .patch].contains(self.method) {
            headers["Content-Type"] = "application/json"
            headers["Accept"] = "application/json"
        }

        urlRequest.headers = headers

        return urlRequest
    }
}
