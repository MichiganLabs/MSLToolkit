import Alamofire
import Foundation

public struct MSLFoundation {
    /**
        @function generateServerTrustManager
        @abstract Generate a ServerTrustManager to be used with AlamoFire to allow for proxying requests
        through Charles running on your development environment. Charles Proxy will only be available
        in DEBUG mode.
        @param charlesCertBundle The bundle containing the Charles Certificate
        @result a ServerTrustManager that allows for the Charles Proxy provided in the bundle if in DEBUG
        or else the AlmoFire DefaultTrustEvaluator
     */
    public static func generateServerTrustManager(charlesCertBundle: Bundle) -> ServerTrustManager {
        return MSLServerTrustManager(charlesCertBundle: charlesCertBundle)
    }
}
