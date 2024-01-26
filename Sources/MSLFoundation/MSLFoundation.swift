import Alamofire
import Foundation

/**
    @abstract Foundational helpers for all Michigan Software Labs projects
 */
public struct MSLFoundation {
    /**
        @function generateServerTrustManager
        @abstract Generate a ServerTrustManager to be used with AlamoFire to allow for proxying requests
        through Charles running on your development environment. Charles Proxy should only be used
        in DEBUG mode.
        @param charlesCertBundle The bundle containing the Charles Certificate
        @result a ServerTrustManager that allows for successful proxying with the provided certifcate
     */
    public static func generateServerTrustManager(charlesCertBundle: Bundle) -> ServerTrustManager {
        return MSLServerTrustManager(charlesCertBundle: charlesCertBundle)
    }
}
