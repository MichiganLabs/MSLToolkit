import Alamofire
import Foundation

/// Foundational helpers for all Michigan Software Labs projects
public enum MSLNetworking {
    /// Builds a Server Trust Evaluator that trusts network requests intended to pass through Charles Proxy.
    /// - Parameter charlesCertBundle: The bundle containing the Charles Certificate
    /// - Returns: A `ServerTrustEvaluating` that allows for successful proxying with the provided certifcate
    public static func charlesProxyEvaluator(_ bundle: Bundle) -> ServerTrustEvaluating {
        return CharlesProxyEvaluator(certBundle: bundle)
    }
}
