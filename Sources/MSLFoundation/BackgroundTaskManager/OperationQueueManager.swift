import Combine
import Logging
import Network
import UIKit

private let logger: Logger = {
    var logger = Logger(label: "\(#file)")
    logger.logLevel = .info
    return logger
}()

protocol QueueManagerListener: AnyObject {
    func didCompleteQueue()
    func didSleepQueue()
}

/// The OperationQueueManager class is responsible for managing a queue of operations, handling their execution,
/// and ensuring thread safety. It provides mechanisms to register operation providers, manage their execution
/// state, and handle background tasks.
///
/// State Management: The OperationQueueManager maintains the state of the queue with three possible states:
/// stopped, sleeping, and running.
///
/// Background Task Management: The class also manages background tasks, allowing certain tasks to continue
/// running even when the app is in the background.
final class OperationQueueManager {
    public enum State {
        case stopped
        case sleeping
        case running
    }

    /// A list of all the currently registered providers
    private var providers = [String: OperationWorkProvider]()

    /// A queue used to lock properties being manipulated on multiple threads
    ///
    /// A really good article on multi-threaded race conditions
    /// https://medium.com/swiftcairo/avoiding-race-conditions-in-swift-9ccef0ec0b26
    private let lockQueue = DispatchQueue(
        label: "OperationQueueManager",
        attributes: .concurrent
    )

    /// Operations of providers that have been enqueued and are currently executing
    private var enqueuedProviders = [String: [Operation]]()

    /// Background tasks that have registered and are allowd to run in the background
    private var backgroundTasks = [String: UIBackgroundTaskIdentifier]()

    /// Timers used for keeping track of how long a provider has been running
    /// and to kill operations if they run for too long
    private var providerExpirationTimers = [String: DispatchSourceTimer]()

    /// Maintains the number of times a provider's operations were scheduled to run in the current time allotment.
    /// Once all providers have had a chance for their operations to be scheduled, the `runCount` is reset to zero.
    private var runCount = [String: Int]()

    /// Maintains the date of the last time a provider was scheduled to do work
    private var lastScheduled = [String: Date]()

    /// The queue that operations of providers are run on.
    /// This queue supports concurrent execution of operations.
    private lazy var operationQueue = OperationQueue()

    /// The next time this queue should run when put to sleep
    public var nextRunDate = Date()

    /// Returns the smallest `desiredFrequency` from its `providers`
    private var minimumDesiredRunFrequency: TimeInterval? {
        // If there are providers that are ready to run _now_, then we return a time of zero.
        if self.providers.values.contains(where: { provider in
            provider.shouldRepeat == false
        }) {
            return 0
        }

        // Otherwise, just return the smallest desired run frequency for the registered providers
        return self.providers.values.map(\.desiredFrequency).min()
    }

    /// A timer that is used to wake up the manager to begin work again
    private var sleepTimer: DispatchSourceTimer?

    private var listeners = [QueueManagerListener]()

    public private(set) var state: State = .stopped

    /// Returns `true` if the queue is currently sleeping with no intention of waking up.
    /// Queue will stay in deep sleep until a new provider is registered.
    private var isDeepSleep: Bool {
        return self.state == .sleeping && (self.sleepTimer?.isCancelled ?? true)
    }

    private let networkMonitor = NWPathMonitor()
    private var networkStatus: NWPath.Status = .requiresConnection

    public init() {
        // Observe network connection
        self.networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.networkStatus = path.status
        }
        self.networkMonitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}

// MARK: Manipulation Functions

extension OperationQueueManager {
    func register(type: EnqueueType = .keep, provider: OperationWorkProvider) {
        let providerAlreadyExists = self.providers.keys.contains(provider.identifier)

        switch type {
        case .keep:
            if providerAlreadyExists {
                // We've choosen to KEEP a work provider that already exists with that identifier
                return
            }
        case .replace:
            self.unregister(provider: provider)
        }

        self.providers[provider.identifier] = provider

        logger.info("Registered provider: \(String(describing: provider.self))")

        if self.isDeepSleep {
            // If we are sleeping with no intention of waking up, wake up now!
            self.start()
        } else {
            // Update the sleep timer in case the new provider has work to do soon
            self.updateSleepTimer()
        }
    }

    func unregister(provider: OperationWorkProvider) {
        self.providers[provider.identifier] = nil
        self.lastScheduled[provider.identifier] = nil

        logger.info("Unregistered provider: \(String(describing: provider.self))")
    }

    func addListener(_ listener: QueueManagerListener) {
        guard self.listeners.contains(where: { $0 === listener }) else { return }
        self.listeners.append(listener)
    }

    func removeListener(_ listener: QueueManagerListener) {
        if let index = self.listeners.firstIndex(where: { $0 === listener }) {
            self.listeners.remove(at: index)
        }
    }

    /// Start processing the queue. It is possible that the queue will go to sleep if
    /// no work is available to perform. Furthermore, if there are no providers registered,
    /// the queue will go into a deep sleep and will not wake up again until another provider is registered.
    func start() {
        guard self.state != .running else { return }

        self.state = .running

        logger.info("Operation queue has been started")

        self.sleepTimer?.cancel()

        /// Add work to process
        self.buildQueue()
    }

    /// Stop the queue from continuing to run.
    func stop() {
        self.state = .stopped

        self.drainOperationQueue()

        logger.info("Operation queue has been stopped")
    }
}

// MARK: Private functions

extension OperationQueueManager {
    // MARK: Sleep Functions

    /// Temporarilly stop the queue. But the queue will wake back up at the earliest frequency of the providers.
    private func sleep() {
        self.state = .sleeping

        self.drainOperationQueue()

        self.updateSleepTimer()

        for listener in self.listeners {
            listener.didSleepQueue()
        }
    }

    /// Creates a timer to restart the queue operation process
    private func updateSleepTimer() {
        guard self.state == .sleeping else { return }

        // if we have providers that want to run at a specific frequency, then we should set a timer
        // to wake us back up.
        if let sleepDuration = self.minimumDesiredRunFrequency {
            let proposedNextRunDate = Date(timeIntervalSinceNow: sleepDuration)
            let now = Date()

            // Don't update `nextRunDate` if it's going to make the queue sleep longer
            if self.nextRunDate > now, proposedNextRunDate > self.nextRunDate {
                return
            }

            self.nextRunDate = proposedNextRunDate

            logger.trace("Setting sleep timer to wake up at: \(self.nextRunDate.description)")

            self.sleepTimer = self.buildTimer(duration: Int(sleepDuration)) { [weak self] in
                logger.trace("Queue waking back up!")
                self?.start()
            }
        } else {
            // Go to into deep sleep (i.e. don't wake up until a provider registers)
            logger.trace("Queue going into deep sleep.")
            self.sleepTimer?.cancel()
        }
    }

    // MARK: Queue Functions

    /// Find providers with obtainable work within given constraints and add them to the operation queue
    private func buildQueue() {
        guard self.state == .running else { return }

        // Don't start executing until we finish building the queue
        self.operationQueue.isSuspended = true

        self.operationQueue.progress.completedUnitCount = 0
        self.operationQueue.progress.totalUnitCount = 0

        let providers = self.getProvidersWithObtainableWork()

        // If there is no work to do, stop the queue and setup a sleepTimer
        guard providers.isNotEmpty else {
            logger.trace("Stopping work because no providers had work to do")
            self.sleep()
            return
        }

        logger.trace("Adding work to the queue...")

        // Build the queue
        for provider in providers {
            self.addOperationsToQueue(for: provider)
        }

        // On completion of queue...
        self.operationQueue.addBarrierBlock {
            logger.trace("Queue did finish all operations!")

            if !self.operationQueue.progress.isFinished {
                let error = "Pogress mismatch! Make sure your Operation calls `super.start()` " +
                    "to keep accurate progress."
                logger.error("\(error)")
            }

            // Reset state
            self.providerExpirationTimers.removeAll()
            self.enqueuedProviders.removeAll()
            self.backgroundTasks.removeAll()

            // Notify listeners of queue completion
            for listener in self.listeners {
                listener.didCompleteQueue()
            }

            // Attempt to add more work to the queue
            self.buildQueue()
        }

        logger.trace("Providers scheduled: \(providers)")
        self.operationQueue.isSuspended = false
    }

    /// Adds the operation and its dependencies to the queue and allows this
    /// work to extend into the background if desired
    private func addOperationsToQueue(for provider: OperationWorkProvider) {
        let operations = provider.buildWork().compactMap { $0 }
        self.enqueuedProviders[provider.identifier] = operations

        for operation in operations {
            // Register this operation to run in the background (if desired)
            if provider.canRunInBackground {
                self.backgroundTasks[provider.identifier] = UIApplication.shared.beginBackgroundTask(
                    expirationHandler: {
                        logger.trace("\(operation.description) EXPIRED: \(Date())")

                        self.sleep()
                    }
                )
            }

            // The operation that signals work has begun
            let startOperation = SimpleOperation(
                mainHandler: {
                    self.lockQueue.sync(flags: [.barrier]) {
                        guard self.providerExpirationTimers[provider.identifier] == nil else { return }

                        logger.trace("Add an expiration timer for provider \(provider.identifier)")

                        self.providerExpirationTimers[provider.identifier] = self.buildTimer(
                            duration: Int(provider.timeoutDuration)
                        ) {
                            logger.error("Provider \(provider.identifier) got killed because it didn't finish in time")
                            for operation in operations {
                                operation.cancel()
                            }
                        }
                    }
                }
            )

            // The operation that signals work has finished
            let operationEndWork = {
                logger.trace("Completed operation: \(operation.description)")

                // End the background task (if there is one)
                if
                    provider.canRunInBackground,
                    let id = self.backgroundTasks[provider.identifier]
                {
                    UIApplication.shared.endBackgroundTask(id)
                }

                // Clean up tasks
                self.lockQueue.sync(flags: [.barrier]) {
                    guard var enqueuedOperations = self.enqueuedProviders[provider.identifier] else { return }

                    // Remove the completed operation from the enqueued list
                    if let index = enqueuedOperations.firstIndex(of: operation) {
                        enqueuedOperations.remove(at: index)
                    }
                    self.enqueuedProviders[provider.identifier] = enqueuedOperations

                    if enqueuedOperations.isEmpty {
                        logger.debug("Completed work for provider: \(provider.identifier)")

                        self.providerExpirationTimers[provider.identifier] = nil
                        self.enqueuedProviders[provider.identifier] = nil
                        self.backgroundTasks[provider.identifier] = nil

                        // Remove any one-time work providers from the queue manager
                        if provider.shouldRepeat == false {
                            self.unregister(provider: provider)
                        }
                    }
                }
            }

            let endOperation = SimpleOperation(
                mainHandler: operationEndWork,
                cancelHandler: operationEndWork
            )

            // Run startOperation first
            // Then operation
            // Finally, endOperation
            operation.addDependency(startOperation)
            endOperation.addDependency(operation)
            self.enqueue(endOperation)
        }
    }

    private func drainOperationQueue() {
        self.operationQueue.cancelAllOperations()
        logger.trace("Emptied operation queue")
    }

    /// Adds the operation and all of its dependencies to the operation queue
    private func enqueue(_ operation: Operation) {
        // Recursively add dependencies of the given operation to the queue
        for dependency in operation.dependencies {
            self.enqueue(dependency)
        }

        // Add operation to queue
        self.operationQueue.progress.totalUnitCount += 1
        self.operationQueue.addOperation(operation)
    }
}

// MARK: Helper Functions

private extension OperationQueueManager {
    /// Returns an array of providers that have work to be done.
    /// This function also considers remaining background time and includes providers that can
    /// complete their work in the given time constraint.
    private func getProvidersWithObtainableWork() -> [OperationWorkProvider] {
        var remainingTime = UIApplication.shared.backgroundTimeRemaining

        // If unit testing...
        if NSClassFromString("XCTest") != nil {
            remainingTime = 30 // seconds
        }

        logger.trace("Remaining background time: \(remainingTime)")

        guard remainingTime > 0 else { return [] }

        var results = [OperationWorkProvider]()

        let providers = self.getProvidersWantingToBeScheduled()
        let sortedIds = self.getProvidersInPriorityOrder(from: providers)

        // Loop through the providers in priority order
        for id in sortedIds {
            guard let provider = providers[id] else { continue }

            // Check the `conditions` and verify all have been met
            var conditionsMet = true
            for condition in provider.conditions {
                switch condition {
                case let .networkStatus(status):
                    if self.networkStatus != status {
                        conditionsMet = false
                        break
                    }
                case let .minimumBatteryLevel(requiredLevel):
                    let device = UIDevice.current
                    let currentBatteryLevel = device.batteryLevel * 100
                    if currentBatteryLevel < requiredLevel {
                        conditionsMet = false
                        break
                    }
                }
            }

            // Verify we have enough time to execute the work provider
            let hasTimeToRun = provider.estimatedWorkTime < remainingTime

            // Schedule the provider to run
            if conditionsMet, hasTimeToRun {
                remainingTime -= provider.estimatedWorkTime
                results.append(provider)

                self.lastScheduled[id] = Date()

                // Increment run count for this provider
                let count = (self.runCount[id] ?? 0) + 1
                self.runCount[id] = count
            }
        }

        return results
    }

    private func getProvidersWantingToBeScheduled() -> [String: OperationWorkProvider] {
        var results = [String: OperationWorkProvider]()
        for (id, provider) in self.providers {
            if provider.shouldRepeat {
                let lastScheduled = self.lastScheduled[id] ?? Date(timeIntervalSince1970: 0)
                let desiredRunTime = Date(
                    timeIntervalSince1970: lastScheduled.timeIntervalSince1970 + provider.desiredFrequency
                )
                let now = Date()

                if now >= desiredRunTime {
                    results[id] = provider
                }
            } else {
                results[id] = provider
            }
        }

        logger.trace("Providers needing to be scheduled: \(results)")

        return results
    }

    /// Gets providers in order of ones that haven't had a chance to run yet
    private func getProvidersInPriorityOrder(from providers: [String: OperationWorkProvider]) -> [String] {
        // Reset run count if all provider's operations have had a chance to run
        if self.runCount.values.min() ?? 0 > 0 {
            self.runCount.removeAll()
        }

        // Pre-fill run count with default values
        for id in providers.keys where self.runCount[id] == nil {
            self.runCount[id] = 0
        }

        // Sort providers based on the ones that have run the least
        let sortedIds = self.runCount.keys.sorted { lhs, rhs in
            return self.runCount[lhs] ?? 0 < self.runCount[rhs] ?? 0
        }

        logger.trace("Providers in priority order: \(sortedIds)")

        return sortedIds
    }

    func buildTimer(duration: Int, work: @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(
            flags: .strict,
            queue: DispatchQueue.global(qos: .background)
        )
        timer.schedule(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(duration))
        timer.setEventHandler(handler: DispatchWorkItem { work() })
        timer.resume()

        return timer
    }
}
