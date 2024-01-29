import Combine

/// A store that retains a reference to object(s) that are required to stay alive in order to function properly
final public class DataStore<Model> {
    private let reference: (any Publishing)?
    public let publisher: AnyPublisher<Model, Never>

    public init<Reference: Publishing>(_ emitter: Reference) where Model == Reference.Output {
        self.reference = emitter
        self.publisher = emitter.publisher
    }

    public init<Reference: Publishing>(
        _ emitter: Reference,
        publisherFactory: (AnyPublisher<Reference.Output, Never>) -> AnyPublisher<Model, Never>
    ) {
        self.reference = emitter
        self.publisher = publisherFactory(emitter.publisher)
    }

    public init(publisher: AnyPublisher<Model, Never>) {
        self.reference = nil
        self.publisher = publisher
    }

    public convenience init(_ model: Model) {
        self.init(publisher: CurrentValueSubject(model).eraseToAnyPublisher())
    }
}
