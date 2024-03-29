import Combine

/**
 PublisherConvertible allows us to mark a variable as @Published without having to rely on SwiftUI's implementation.
 This will expose a Publisher.
 */
@propertyWrapper
public class PublisherConvertible<T> {
    public var wrappedValue: T {
        willSet {
            subject.send(newValue)
        }
    }

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    private lazy var subject = CurrentValueSubject<T, Never>(wrappedValue)
    public var projectedValue: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
}
