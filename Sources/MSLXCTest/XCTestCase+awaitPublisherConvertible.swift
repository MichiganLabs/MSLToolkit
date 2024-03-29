import Combine
import Foundation
import XCTest

public extension XCTestCase {
    /// Reusable test case to wait for a PublisherConvertible publisher to publish a value
    func awaitPublisherConvertible<T>(
        _ publisherConvertible: AnyPublisher<T, Never>,
        timeout: TimeInterval = 10
    ) -> T? {
        let expectation = expectation(description: "Awaiting publisher convertible")
        var publishedValue: T?
        let cancellable = publisherConvertible.sink(
            receiveValue: { value in
                publishedValue = value
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: timeout)
        cancellable.cancel()
        return publishedValue
    }

    /// Reusable test case to wait for an @Published's publisher to emit a value
    func awaitPublished<T>(
        _ published: Published<T>.Publisher,
        timeout: TimeInterval = 4,
        maxCountPublished: Int = 10,
        when perform: () -> Void = {}
    ) -> [T] {
        let expectation = expectation(description: "Awaiting published")
        var publishedValue: [T] = []
        let cancellable = published
            .collect(.byTimeOrCount(RunLoop.main, .seconds(Int(timeout)), maxCountPublished))
            .sink { value in
                publishedValue = value
                expectation.fulfill()
            }

        perform()

        wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
        return publishedValue
    }
}
