import BackgroundTasks

/// Create another class that conforms to this class to help manage your async operation
/// https://www.avanderlee.com/swift/asynchronous-operations/
open class AsyncOperation: Operation {
    private let lockQueue: DispatchQueue

    public init(label: String) {
        self.lockQueue = DispatchQueue(label: label, attributes: .concurrent)
    }

    override public var isAsynchronous: Bool {
        return true
    }

    private var _isExecuting = false
    override public private(set) var isExecuting: Bool {
        get {
            return self.lockQueue.sync { () -> Bool in
                return self._isExecuting
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            self.lockQueue.sync(flags: [.barrier]) {
                self._isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _isFinished = false
    override public private(set) var isFinished: Bool {
        get {
            return self.lockQueue.sync { () -> Bool in
                return self._isFinished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            self.lockQueue.sync(flags: [.barrier]) {
                self._isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }

    override open func cancel() {
        super.cancel()

        self.finish()
    }

    override public func start() {
        super.start() // calls main()

        guard !self.isCancelled else {
            self.finish()
            return
        }

        self.isFinished = false
        self.isExecuting = true
    }

    override open func main() {
        fatalError("Subclasses must implement `main` without overriding super.")
    }

    public func finish() {
        guard self.isExecuting else { return }

        self.isExecuting = false
        self.isFinished = true
    }
}
