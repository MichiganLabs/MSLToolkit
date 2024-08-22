import Alamofire
import Foundation

/// Use this in your dependency injection to obfuscate the underlying session manager
public protocol ApiRouterRequestable {
    func request(
        from request: ApiRouter
    ) async throws -> HTTPURLResponse

    func request<Response: Decodable>(
        from request: ApiRouter,
        using decoder: JSONDecoder?
    ) async throws -> Response

    func request<Response: Decodable>(
        from request: ApiRouter
    ) async throws -> Response

    func request<Response: Decodable, Property: Any>(
        _ keyPath: KeyPath<Response, Property>,
        from request: ApiRouter,
        using decoder: JSONDecoder?
    ) async throws -> Property

    func request<Response: Decodable, Property: Any>(
        _ keyPath: KeyPath<Response, Property>,
        from request: ApiRouter
    ) async throws -> Property
}
