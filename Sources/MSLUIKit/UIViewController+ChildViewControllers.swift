import UIKit

public extension UIViewController {
    /// Add a child view controller to `view` and make it fill the space
    func embed(childViewController viewController: UIViewController) {
        self.embed(childViewController: viewController, in: self.view)
    }

    /// Add child view controller to the provided `container` view and make it fill the space
    func embed(childViewController viewController: UIViewController, in container: UIView) {
        self.add(childViewController: viewController, in: container)
        viewController.view.frame = container.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    /// Add a child view controller to `view`
    func add(childViewController viewController: UIViewController) {
        self.add(childViewController: viewController, in: self.view)
    }

    /// Add a child view controller to the provided `container`
    func add(childViewController viewController: UIViewController, in container: UIView) {
        self.addChild(viewController)
        container.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }

    /// Remove a child view controller
    func remove(childViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    /// Replace existing child view controllers with the one provided and embed it inside the `container` view.
    func replaceContents(with childViewController: UIViewController, in container: UIView? = nil) {
        // Remove previous child view controllers (if there are any)
        for child in self.children {
            self.remove(childViewController: child)
        }

        // Add new child view controller
        if let container {
            self.embed(childViewController: childViewController, in: container)
        } else {
            self.embed(childViewController: childViewController)
        }
    }
}
