import Foundation

public enum HTTPStatusCode {
    public static let ok = 200
    public static let badRequest = 400
    public static let unauthorized = 401
    public static let notFound = 404
    public static let found = 302

    public static let informational = 100..<200
    public static let successful = 200..<300
    public static let redirect = 300..<400
    public static let clientError = 400..<500
    public static let serverError = 500..<600
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
