@testable import MSLFoundation
import XCTest

private var oneTimeJobCounter = 0
private var repeatingJobCounter = 0

final class BackgroundTaskManagerTests: XCTestCase {
    private class OneTimeJob: OperationWorkProvider {
        let identifier = "OneTimeJob"
        let shouldRepeat = false

        func buildWork() -> [Operation] {
            return [
                SimpleOperation(mainHandler: {
                    oneTimeJobCounter += 1
                }),
            ]
        }
    }

    private class RepeatingJob: OperationWorkProvider {
        let identifier = "RepeatingJob"
        let shouldRepeat = true
        let desiredFrequency: TimeInterval = 2 // seconds

        func buildWork() -> [Operation] {
            return [
                SimpleOperation(mainHandler: {
                    repeatingJobCounter += 1
                }),
            ]
        }
    }

    private class FailingAsyncJob: OperationWorkProvider {
        let identifier = "FailingAsyncJob"
        let shouldRepeat = false
        let timeoutDuration: TimeInterval = 2

        private class FailingOperation: AsyncOperation {
            init() {
                super.init(label: "FailingOperation")
            }

            override func main() {
                print("Doesn't call self.finish on purpose")
            }
        }

        func buildWork() -> [Operation] {
            return [
                FailingOperation(),
            ]
        }
    }

    private class SuccessfulAsyncJob: OperationWorkProvider {
        let identifier = "SuccessfulAsyncJob"
        let shouldRepeat = false
        let timeoutDuration: TimeInterval = 3

        let expectation = XCTestExpectation(description: "Successful Async job finishes")

        private class SuccessOperation: AsyncOperation {
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
                super.init(label: "FailingOperation")
            }

            override func main() {
                print("Successful Async Job Start")

                DispatchQueue.global(qos: .background).async {
                    Thread.sleep(forTimeInterval: 2)
                    self.finish()

                    self.expectation.fulfill()
                }
            }
        }

        func buildWork() -> [Operation] {
            return [
                SuccessOperation(expectation: self.expectation),
            ]
        }
    }

    func testOperationQueue() {
        let manager = OperationQueueManager()
        XCTAssert(manager.state == .stopped)

        manager.start()

        // Should not be doing anything because we haven't registered anything yet
        XCTAssert(manager.state == .sleeping)

        manager.register(provider: OneTimeJob())
        manager.register(provider: RepeatingJob())

        // Failing job is strategically placed here to verify that other jobs still get
        // run even if one fails in the middle.
        manager.register(provider: FailingAsyncJob())

        let successfulJob = SuccessfulAsyncJob()
        manager.register(provider: successfulJob)

        XCTAssert(manager.state == .running)

        Thread.sleep(forTimeInterval: 1)

        // Verify that after 1 second, both of the first jobs have run once
        XCTAssert(oneTimeJobCounter == 1)
        XCTAssert(repeatingJobCounter == 1)

        // Verify that the successful async job finishes
        wait(for: [successfulJob.expectation], timeout: 10)

        // Verify that the repeating job _did_ run again
        XCTAssert(repeatingJobCounter == 2)

        Thread.sleep(forTimeInterval: 2)

        // Verify that the one time job did _not_ run again
        XCTAssert(oneTimeJobCounter == 1)

        // Verify that the repeating job _did_ run again
        XCTAssert(repeatingJobCounter == 3)
    }
}
