import Alamofire
import Foundation

internal class CharlesProxyEvaluator: ServerTrustEvaluating {
    let certBundle: Bundle
    
    init(certBundle: Bundle) {
        self.certBundle = certBundle
    }
    
    func evaluate(_ trust: SecTrust, forHost host: String) throws {
        self.trust(trust, host: host)
        try Self.evaluate(trust: trust)
    }

    /// Trusts the specified hostname alongside our pinned Charles certificate
    private func trust(_ trust: SecTrust, host: String) {
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(trust, policy)

        let certificates: [SecCertificate] = self.certBundle.af.paths(
            forResourcesOfTypes: [".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]
        )
        .compactMap { path in
            guard
                let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData,
                let certificate = SecCertificateCreateWithData(nil, certificateData)
            else { return nil }

            return certificate
        }

        SecTrustSetAnchorCertificates(
            trust,
            certificates as CFArray
        )
        SecTrustSetAnchorCertificatesOnly(trust, false)
    }

    /// Evaluate that the SecTrust matches one of our certificates supplied in SecTrustSetAnchorCertificates OR
    /// the certificate matches one of our supplied hosts
    private static func evaluate(trust: SecTrust) throws {
        var error: CFError?
        _ = SecTrustEvaluateWithError(trust, &error)

        if let error {
            throw AFError.serverTrustEvaluationFailed(reason: .trustEvaluationFailed(error: error))
        }
    }
}


internal final class MSLServerTrustManager: ServerTrustManager {
    
    private let serverTrustEvaluating: ServerTrustEvaluating
    
    public init(charlesCertBundle: Bundle) {
        self.serverTrustEvaluating = CharlesProxyEvaluator(certBundle: charlesCertBundle)
        super.init(evaluators: [:])
    }
    
    override public func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        return self.serverTrustEvaluating
    }
}
