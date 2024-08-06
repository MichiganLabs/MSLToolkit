import BackgroundTasks
import Combine
import Foundation
import Logging
import UIKit

private let logger: Logger = {
    var logger = Logger(label: "\(#file)")
    logger.logLevel = .info
    return logger
}()

public enum EnqueueType {
    case replace
    case keep
}

public final class BackgroundTaskManager {
    private let taskIdentifier: String

    private let queue = OperationQueueManager()

    /// The current background refresh task that woke up the application
    private var backgroundTask: BGAppRefreshTask?

    public init(
        taskId: String
    ) {
        self.taskIdentifier = taskId

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: self.taskIdentifier,
            using: nil
        ) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleBackgroundTask(task)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleActivate(_:)),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleDeactivate(_:)),
            name: UIScene.willDeactivateNotification,
            object: nil
        )

        self.queue.addListener(self)
    }

    deinit {
        self.queue.removeListener(self)
    }
}

// MARK: Public Functions

public extension BackgroundTaskManager {
    func register(type: EnqueueType = .keep, provider: OperationWorkProvider) {
        self.queue.register(type: type, provider: provider)
    }

    func unregister(provider: OperationWorkProvider) {
        self.queue.unregister(provider: provider)
    }

    func start() {
        self.queue.start()
    }

    func stop() {
        self.queue.stop()
    }
}

// MARK: Helpers

extension BackgroundTaskManager {
    @objc private func handleActivate(_ notification: Notification) {
        BGTaskScheduler.shared.cancel(
            taskRequestWithIdentifier: self.taskIdentifier
        )
    }

    @objc private func handleDeactivate(_ notification: Notification) {
        self.scheduleBackgroundTasks()
    }

    private func scheduleBackgroundTasks() {
        let backgroundTask = BGAppRefreshTaskRequest(identifier: self.taskIdentifier)
        backgroundTask.earliestBeginDate = self.queue.nextRunDate

        do {
            try BGTaskScheduler.shared.submit(backgroundTask)

            BGTaskScheduler.shared.getPendingTaskRequests { tasks in
                let details = tasks.map(\.description).joined(separator: "\n")
                logger.debug("\(tasks.count) background tasks scheduled:\n\(details)")
            }
        } catch {
            logger.error("Failed to schedule background tasks!")
            logger.error("\(error.localizedDescription)")
        }
    }

    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        defer {
            // Schedule the next background task
            self.scheduleBackgroundTasks()
        }

        logger.info("App woke up for background refresh task: \(task.description)")

        self.backgroundTask = task

        self.queue.start()

        task.expirationHandler = {
            logger.info("Background refresh task expired")

            self.queue.stop()

            self.backgroundTask = nil
        }
    }
}

extension BackgroundTaskManager: QueueManagerListener {
    func didCompleteQueue() {
        logger.info("Background task completed 1 round of work")
    }

    func didSleepQueue() {
        logger.info("Background work did finish")

        self.backgroundTask?.setTaskCompleted(success: true)
        self.backgroundTask = nil
    }
}
