#  ApiSessionManager

`ApiSessionManager` is a base class designed to manage a network session and greatly simplify the process of making network requests.

## Example Usage

### Creating an API

To create an API using `ApiSessionManager`, you need to subclass it and configure a `Session`. Here's an example:


```swift
class API: ApiSessionManager {
    static let shared = API()
    
    var user: String? = nil

    init() {
        let adapter = NetworkAdapter(host: "api.example.com", authHandler: { request in
            var request = request

            if let user = Self.shared.user {
                request.addValue(user, forHTTPHeaderField: "X-API-KEY")
            }

            return request
        })

        let interceptor = Interceptor(adapters: [adapter])
        super.init(session: Session(interceptor: interceptor))
    }
}
```

In this example:

* `API` is a singleton class that subclasses `ApiSessionManager`.
* A `NetworkAdapter` is created with a host and an authentication handler that adds an X-API-KEY header if the user is set.
* An Interceptor is created with the adapter and passed to the Session initializer.
* The `super.init(session:)` call initializes the `ApiSessionManager` with the configured session.

### Using a Router
To make network requests, you can define an enum that conforms to `ApiRouter`. This enum will represent the different endpoints of your API.

```swift
enum Endpoint: ApiRouter {

    case getUserInfo(id: Int)
    case updateProfile(id: Int, data: MyData)

    var method: HTTPMethod {
        switch self {
        case .getUserInfo:
            return .get
        case .updateProfile:
            return .post
        }
    }

    var path: String {
        switch self {
        case .getUserInfo:
            return "/v1/user"
        case .updateProfile(let id, let data):
            return "/v1/profile/\(id)"
        }
    }

    public func asURLRequest() throws -> URLRequest {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        var urlRequest = self.baseRequest

        switch self {
        case .getUserInfo(let id):
            // Query parameters
            urlRequest = try URLEncoding.default.encode(urlRequest, with: ["userId": id])
        case .updateProfile(let data):
            // Request body
            urlRequest.httpBody = try? encoder.encode(data)
        }

        return urlRequest
    }
}
```

In this example:

* `Endpoint` is an enum that conforms to `ApiRouter`.
* Each case in the enum represents a different API endpoint.
* The `method` property returns the HTTP method for each endpoint.
* The `path` property returns the URL path for each endpoint.
* The `asURLRequest()` function builds the `URLRequest` to be sent via the `Session` from our `API` class.

### Making a Request
To make a request using the `API` and `Endpoint`, you can use the following code:

```swift
func getUser(id: Int) async throws -> User {
    return try await API.shared.request(from: Endpoint.getUser(id: 1))
}
```
