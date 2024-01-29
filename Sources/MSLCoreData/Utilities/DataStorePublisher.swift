import CoreData
import Combine
import MSLFoundation

protocol ModelConvertible {
    associatedtype Model: Any
    func toModel() -> Model
}

/// Wraps NSFetchedResultsController and converts the delegate callback methods into a publisher (stream)
final class DataStorePublisher<
    Model,
    EntityType: ModelConvertible & NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate, Publishing {

    private(set) var fetchedRequestController: NSFetchedResultsController<EntityType>
    private let toModelHandler: ((EntityType) -> Model?)?
    /// Unforunately NSFetchResultsController doesn't honor limits on published changes, so we have to enforce it here
    private let limit: Int?

    @PublisherConvertible
    private var results = [Model]()

    public init(
        fetchedRequestController: NSFetchedResultsController<EntityType>,
        limit: Int? = nil,
        toModelHandler: ((EntityType) -> Model?)? = nil
    ) {
        self.fetchedRequestController = fetchedRequestController
        self.limit = limit
        self.toModelHandler = toModelHandler

        super.init()
        self.fetchedRequestController.delegate = self

        self.fetchedRequestController.managedObjectContext.perform {
            try? self.fetchedRequestController.performFetch()
            self.emitObjects(for: self.fetchedRequestController)
        }
    }

    public var publisher: AnyPublisher<[Model], Never> {
        return self.$results
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let controller = controller as? NSFetchedResultsController<EntityType> else { return }
        self.emitObjects(for: controller)
    }

    private func emitObjects(for controller: NSFetchedResultsController<EntityType>) {
        let fetchedOjects = controller.fetchedObjects?.compactMap({ requestResult -> Model? in
            if let toModelHandler = self.toModelHandler {
                return toModelHandler(requestResult)
            } else {
                return requestResult.toModel() as? Model
            }
        })

        if let limit = self.limit,
           let fetchedOjects = fetchedOjects,
           fetchedOjects.count >= limit {
            self.results = Array(fetchedOjects.prefix(upTo: limit))
        } else {
            self.results = fetchedOjects ?? []
        }
    }
}

