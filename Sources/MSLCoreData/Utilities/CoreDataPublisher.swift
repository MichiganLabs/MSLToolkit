import Combine
import CoreData
import MSLFoundation

public protocol ModelConvertible {
    associatedtype Model: Any
    func toModel() -> Model
}

/// Wraps NSFetchedResultsController and converts the delegate callback methods into a publisher (stream)
public final class CoreDataPublisher<
    EntityType: ModelConvertible & NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate, Publishing {
    private(set) var fetchedRequestController: NSFetchedResultsController<EntityType>
    private let toModelHandler: ((EntityType) -> EntityType.Model?)?

    /// Limit's the number of objects returned.
    /// Unforunately NSFetchResultsController doesn't honor limits on published changes, so we have to enforce it here.
    private let limit: Int?

    @PublisherConvertible
    private var results = [EntityType.Model]()

    /// Returns a publisher for the results emitted from CoreData
    public var publisher: AnyPublisher<[EntityType.Model], Never> {
        return self.$results
    }

    public init(
        fetchedRequestController: NSFetchedResultsController<EntityType>,
        limit: Int? = nil,
        toModelHandler: ((EntityType) -> EntityType.Model?)? = nil
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

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let controller = controller as? NSFetchedResultsController<EntityType> else { return }
        self.emitObjects(for: controller)
    }

    private func emitObjects(for controller: NSFetchedResultsController<EntityType>) {
        let fetchedOjects = controller.fetchedObjects?.compactMap { requestResult -> EntityType.Model? in
            if let toModelHandler = self.toModelHandler {
                return toModelHandler(requestResult)
            } else {
                return requestResult.toModel()
            }
        }

        if let limit = self.limit,
           let fetchedOjects,
           fetchedOjects.count >= limit
        {
            self.results = Array(fetchedOjects.prefix(upTo: limit))
        } else {
            self.results = fetchedOjects ?? []
        }
    }
}
