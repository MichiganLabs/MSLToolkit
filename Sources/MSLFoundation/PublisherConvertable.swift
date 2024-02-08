import Combine
import Foundation

@propertyWrapper
public class PublisherConvertible<T> {
    public var wrappedValue: T {
        willSet {
            self.subject.send(newValue)
        }
    }

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    private lazy var subject = CurrentValueSubject<T, Never>(self.wrappedValue)
    public var projectedValue: AnyPublisher<T, Never> {
        return self.subject.eraseToAnyPublisher()
    }
}
