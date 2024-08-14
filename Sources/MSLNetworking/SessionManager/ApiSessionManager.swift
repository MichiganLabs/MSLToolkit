import Alamofire
import Foundation

open class ApiSessionManager {
    public typealias ErrorHandler = (DataResponse<Data, AFError>) -> Error

    public let session: Session

    /// Default validation will be used if none is specified
    let apiValidation: Alamofire.DataRequest.Validation?

    /// Handler for converting responses returned by the API after failing validation
    let apiErrorHandler: ErrorHandler?

    /// The default decoder to be used on all out going requests
    let decoder: JSONDecoder

    /// Initializes a new instance of `ApiSessionManager`.
    ///
    /// - Parameters:
    ///   - session: The `Session` instance to be used for making network requests. Defaults to `Session.default`.
    ///   - validation: An optional validation closure that will be used to validate the response. If no validation
    ///   is provided, the default Alamofire validation will be used. Defaults to `nil`.
    ///   - errorHandler: An optional error handler closure that will be used to handle errors in the response.
    ///   Defaults to `nil`.
    public init(
        session: Session = Session.default,
        decoder: JSONDecoder? = nil,
        validation: Alamofire.DataRequest.Validation? = nil,
        errorHandler: ErrorHandler? = nil
    ) {
        self.session = session
        self.apiValidation = validation
        self.apiErrorHandler = errorHandler
        self.decoder = decoder ?? JSONDecoder()
    }

    private func execute(_ request: ApiRouter) async throws -> Data {
        let dataRequest: DataRequest = if let multipartFormData = request.multipartFormData {
            self.session.upload(multipartFormData: multipartFormData, with: request)
        } else {
            self.session.request(request)
        }

        let response = await dataRequest
            .validate(customValidator: request.validationOverride ?? self.apiValidation)
            .serializingData()
            .response

        switch response.result {
        case let .success(data):
            return data
        case let .failure(error):
            if let handler = request.errorHandlerOverride ?? self.apiErrorHandler {
                throw handler(response)
            } else {
                throw error
            }
        }
    }
}

extension ApiSessionManager: ApiRouterRequestable {
    public func request<Response: Decodable>(
        from request: ApiRouter
    ) async throws -> Response {
        return try await self.request(from: request, using: self.decoder)
    }

    public func request<Response: Decodable>(
        from request: ApiRouter,
        using decoder: JSONDecoder? = nil
    ) async throws -> Response {
        let decoder = decoder ?? self.decoder

        let data = try await self.execute(request)
        return try decoder.decode(Response.self, from: data)
    }

    public func request<Property: Any>(
        _ keyPath: KeyPath<some Decodable, Property>,
        from request: ApiRouter
    ) async throws -> Property {
        return try await self.request(keyPath, from: request, using: self.decoder)
    }

    public func request<Response: Decodable, Property: Any>(
        _ keyPath: KeyPath<Response, Property>,
        from request: ApiRouter,
        using decoder: JSONDecoder? = nil
    ) async throws -> Property {
        let decoder = decoder ?? self.decoder

        let data = try await self.execute(request)
        let decoded = try decoder.decode(Response.self, from: data)
        return decoded[keyPath: keyPath]
    }
}

// MARK: Response Validation

private extension DataRequest {
    @discardableResult
    func validate(
        customValidator: Alamofire.DataRequest.Validation? = nil
    ) -> Self {
        if let customValidator {
            return self.validate { request, response, data in
                return customValidator(request, response, data)
            }
        } else {
            // Default validation
            return self.validate()
        }
    }
}
