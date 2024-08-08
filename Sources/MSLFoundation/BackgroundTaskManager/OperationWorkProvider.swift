import BackgroundTasks
import Foundation
import Network

public enum OperationWorkProviderCondition {
    case networkStatus(NWPath.Status)

    // Requires UIDevice.current.isBatteryMonitoringEnabled be set to `true`
    case minimumBatteryLevel(Float)
}

/// A protocol that defines the requirements for a provider that supplies work operations.
/// Conforming types are expected to provide information about the work they perform,
/// including estimated execution time, timeout duration, desired frequency, and conditions
/// under which the work should be repeated or allowed to run in the background.
public protocol OperationWorkProvider: AnyObject {
    /// A unique identifier for the work provider.
    var identifier: String { get }

    /// An estimate on how long the work will take to execute.
    var estimatedWorkTime: TimeInterval { get }

    /// If the job does not complete within the specified `timeoutDuration`, then the job will be killed.
    /// This helps prevent a job from going on forever.
    var timeoutDuration: TimeInterval { get }

    /// Specifies how often this worker would like to be run.
    /// The desired requency is only considered if `shouldRepeat` is `true`.
    var desiredFrequency: TimeInterval { get }

    /// Indicates whether or not this work should be repeated again in the future
    var shouldRepeat: Bool { get }

    /// Indicates if this job is allowed to run when the app is backgrounded
    var canRunInBackground: Bool { get }

    /// All conditions must be true in order for this worker to run
    var conditions: [OperationWorkProviderCondition] { get }

    /// Returns operations that this provider would like to be added to the queue
    /// - Returns: An array of `Operation` objects representing the work to be performed.
    func buildWork() -> [Operation]
}

public extension OperationWorkProvider {
    var identifier: String {
        return String(describing: type(of: self))
    }

    // Override this to a smaller value if you want your task to potentially run multiple times
    // in the background. (Normally the OS only gives us 30 seconds to operate in the background).
    var estimatedWorkTime: TimeInterval {
        return 5
    }

    // Override this in order to allow your job to run longer, if desired.
    var timeoutDuration: TimeInterval {
        return 15
    }

    // Defaults to 1 hour
    var desiredFrequency: TimeInterval {
        return 60 * 60
    }

    // Defaults to allowing operations run in the background
    var canRunInBackground: Bool {
        return true
    }

    // Defaults to no conditions
    var conditions: [OperationWorkProviderCondition] {
        return []
    }
}
