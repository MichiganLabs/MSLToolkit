import UIKit

// swiftlint:disable line_length
// swiftformat:disable wrapSingleLineComments
/// Protocol to coordinate UIViewControllers
///
/// Coordinators are objects that are designed to live a level above
/// a UIViewController in the app hierarchy. A Coordinator should encapsulate
/// a task that the user can undertake which may span multiple view controllers,
/// require network requests, are best described using a state machine. The
/// Coordinator should enacapsulate the logic necessary to navigate between
/// screens / states and should delegate subtasks to sub-Coordinators.
///
/// The goal of the Coordinator pattern is to reduce the overall size and
/// and complexity of UIViewControllers by encapsulating logic not directly
/// relevant to _controlling_ the view.
///
/// A `UIViewController` should communicate with its `Coordinator` via a delegate protocol.
/// This decouples a `UIViewController` from how it is used in the view hierarchy,
/// making view controllers more modular / reusable. This delegate should describe the
/// actions that the view controller can trigger, e.g.
/// ```
/// func controller(_ controller: LoginViewController, authenticateWithUsername username: String, password: String)
/// func controller(_ controller: LoginViewController, requestNewUserFormWithUsername username: String?)
/// ```
///
/// `Coordinator`s should communicate with their parent `GroupCoordinator` using a delegate as well.
/// This delegate should describe the potential outcomes of a task, e.g.
/// ```
/// func coordinator(_ coordinator: LoginCoordinator, authenticated user: User)
/// func coordinator(_ coordinator: LoginCoordinator, registered newUser: User)
/// ```
///
/// Some additional resources on this pattern
/// - [http://khanlou.com/2015/01/the-coordinator/](http://khanlou.com/2015/01/the-coordinator/)
/// - [http://khanlou.com/2015/10/coordinators-redux/](http://khanlou.com/2015/10/coordinators-redux/)
/// - [https://will.townsend.io/2016/an-ios-coordinator-pattern](https://will.townsend.io/2016/an-ios-coordinator-pattern)
public protocol Coordinator: AnyObject {
    /// Entry point for beginning a the task for the Coordinator
    ///
    /// This function should return a UIViewController representing the start of the
    /// coordinator's task. This allows the caller (usually a parent coordinator) to decide
    /// how to contain its children (e.g. in a UINavigationController or UIPageViewController)
    /// without coupling that information to the child.
    ///
    /// This method can be called more than once. It is therefore the implementing class's responsibility
    /// to determine what (if anything) should be re-instantiated in this method.
    ///
    /// - returns: UIViewController
    func start() -> UIViewController

    /// The parent coordinator will call this method if it would like the child coordinator to stop
    /// any resource intensive processes. The parent will call `start` again when it is ready for the child to resume.
    func pause()

    /// The parent coordinator will call this method when it no longer has any need for the child coordinator.
    /// Put any de-init logic here.
    func finish()
}

// swiftformat:enable wrapSingleLineComments
// swiftlint:enable line_length

public extension Coordinator {
    func pause() {}
    func finish() {}
}

/// Protocol to coordinate other `Coordinators`
public protocol CoordinatorGroup: Coordinator {
    /// A container for retaining child coordinators so that they do not get de-allocated
    /// WARNING: Do not set this property, it will be managed for you.
    var childCoordinators: [Coordinator] { get set }

    /// Implementation point for specifying how this Coordinator will embed
    /// the view controllers of its children
    ///
    /// An example implementation of this might look something like:
    ///
    /// ```
    /// func embed(viewController: UIViewController, forChild coordinator: Coordinator) {
    ///    self.navigationController.pushViewController(viewController, animated: true)
    /// }
    /// ```
    ///
    /// - Parameter viewController: The UIViewController corresponding to the start of the Coordinator
    /// - Parameter coordinator: The started child Coordinator
    func embed(viewController: UIViewController, forChild coordinator: Coordinator)

    /// Implementation point for specifying how this Coordinator will be removed from view.
    ///
    /// For example:
    /// ```
    /// func embed(coordinator: Coordinator) {
    ///    self.navigationController.presentedViewController?.dismiss(animated: true)
    /// }
    /// ```
    ///
    /// - Parameter coordinator: The Coordinator being removed from view.
    func eject(coordinator: Coordinator)
}

public extension CoordinatorGroup {
    func eject(coordinator _: Coordinator) {}

    /// Convenience method for starting a subtask, retaining the coordinator
    /// and showing the tasks initial view controller
    ///
    /// Please note: It is the responsibility of the parent coordinator to keep a reference to the child coordinator
    /// as it will otherwise be de-allocated.
    ///
    /// - Parameter coordinator: A Coordinator to start, embed, and retain
    /// - returns: The UIViewController returned by starting the provided Coordinator
    @discardableResult
    func start(child coordinator: Coordinator) -> UIViewController {
        // Start can be called multiple times on the same coordinator. For this reason, we should check to see
        // if it already exists in the `childCoordinators` array before adding it.
        if self.childCoordinators.contains(where: { $0 === coordinator }) == false {
            // Save the coordinator so that it is retained
            self.childCoordinators.append(coordinator)
        }

        let controller = coordinator.start()
        self.embed(viewController: controller, forChild: coordinator)
        return controller
    }

    /// Called when the coordinator is no longer needed or associated with a parent coordinator.
    func finish(child coordinator: Coordinator) {
        self.eject(coordinator: coordinator)

        // Finish all child coordinators if applicable
        if let coordinatorGroup = coordinator as? CoordinatorGroup {
            for child in coordinatorGroup.childCoordinators {
                coordinatorGroup.finish(child: child)
            }
        }

        coordinator.finish()

        // Remove the coordinator so that we do not retain it anymore
        if let index = self.childCoordinators.firstIndex(where: { $0 === coordinator }) {
            self.childCoordinators.remove(at: index)
        }
    }

    /// Starts a new coordinator and passes the current one
    func push(_ coordinator: Coordinator) {
        if let current = self.currentCoordinator {
            current.pause()
        }

        self.start(child: coordinator)
    }

    /// Finishes the current coordinator and resumes the previous one
    func pop() {
        guard let coordinator = self.childCoordinators.last else { return }

        self.finish(child: coordinator)

        if let next = self.childCoordinators.last {
            self.start(child: next)
        }
    }

    /// Hot swaps out all current coordinators with the ones provided
    func replace(with coordinators: [Coordinator]) {
        for coordinator in self.childCoordinators {
            self.finish(child: coordinator)
        }

        self.childCoordinators = coordinators

        if let next = self.childCoordinators.last {
            self.start(child: next)
        }
    }

    /// Returns the current coordinator
    var currentCoordinator: Coordinator? {
        return self.childCoordinators.last
    }
}
