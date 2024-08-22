import Foundation

/// A simple subclass of `Operation` that allows for custom main and cancel handlers.
/// This class provides a straightforward way to define the work to be done in an operation
/// and the actions to take if the operation is cancelled.
public final class SimpleOperation: Operation {
    private(set) var mainHandler: () -> Void
    private(set) var cancelHandler: () -> Void

    public init(
        mainHandler: (() -> Void)? = nil,
        cancelHandler: (() -> Void)? = nil
    ) {
        self.mainHandler = mainHandler ?? {}
        self.cancelHandler = cancelHandler ?? {}
    }

    override public func main() {
        self.mainHandler()
    }

    override public func cancel() {
        super.cancel()
        self.cancelHandler()
    }
}
