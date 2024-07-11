import Foundation

public enum HTTPStatusCode {
    /// OK (200)
    public static let ok = 200

    /// Bad Request (400)
    public static let badRequest = 400

    /// Unauthorized (401)
    public static let unauthorized = 401

    /// Forbidden (403)
    public static let notFound = 404

    /// Not Found (404)
    public static let found = 302

    /// Informational (100-199)
    public static let informational = 100 ..< 200

    /// Successful (200-299)
    public static let successful = 200 ..< 300

    /// Redirect (300-399)
    public static let redirect = 300 ..< 400

    /// Client Error (400-499)
    public static let clientError = 400 ..< 500

    /// Server Error (500-599)
    public static let serverError = 500 ..< 600
}

public extension HTTPURLResponse {
    var isInformational: Bool {
        return HTTPStatusCode.informational ~= self.statusCode
    }

    var isSuccess: Bool {
        return HTTPStatusCode.successful ~= self.statusCode
    }

    var isRedirect: Bool {
        return HTTPStatusCode.redirect ~= self.statusCode
    }

    var isClientError: Bool {
        return HTTPStatusCode.clientError ~= self.statusCode
    }

    var isServerError: Bool {
        return HTTPStatusCode.serverError ~= self.statusCode
    }
}
