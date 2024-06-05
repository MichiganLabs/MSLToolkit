import Combine

///
/// @PublisherConvertible provides a convenient way to build a publisher around a specific property.
/// This is particularly useful when you want to subscribe to the changing of the property's values.
///
/// Example:
///
/// ```
/// @PublisherConvertible
/// private var shouldRefresh = false
/// ...
/// self.$shouldRefresh
///       .sink { [weak self] _ in
///             // do stuff here...
///       }
///       .store(in: &self.cancellables)
/// ```
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

    private lazy var subject = CurrentValueSubject<T, Never>(wrappedValue)
    public var projectedValue: AnyPublisher<T, Never> {
        self.subject.eraseToAnyPublisher()
    }
}
