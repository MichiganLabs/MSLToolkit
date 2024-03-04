import Alamofire

/// A Server Trust Manager with designed to uses the provided `evaluators` first, and then
/// fall back to the `defaultEvaluator` in the case an evaluator was not provided for a specific host.
public final class MSLServerTrustManager: ServerTrustManager {

    public var defaultEvaluator: ServerTrustEvaluating?

    public init(
        allHostsMustBeEvaluated: Bool = true,
        evaluators: [String: ServerTrustEvaluating],
        defaultEvaluator: ServerTrustEvaluating? = nil
    ) {
        self.defaultEvaluator = defaultEvaluator

        super.init(allHostsMustBeEvaluated: allHostsMustBeEvaluated, evaluators: evaluators)
    }

    override public func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        if let evaluator = self.evaluators[host] {
            return evaluator
        } else if let evaluator = self.defaultEvaluator {
            return evaluator
        } else {
            return nil
        }
    }
}
