import CoreData
import Foundation

public final class DatabaseManager {
    public let name: String
    public let container: NSPersistentContainer

    /// The `viewContext` from the persistent container
    public var viewContext: NSManagedObjectContext {
        return self.container.viewContext
    }

    /// Creates and returns a new background context
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = self.container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// A convenience initializer to create a `DatabaseManager` with _all_ models in the specified bundle
    /// - Parameters:
    ///   - bundle: The `Bundle` containing the CoreData `NSManagedObjectModel`(s)
    ///   - containerName: The name given to the `NSPersistentContainer`
    ///   - inMemoryOnly: Determines if this database should be created in memory only
    public convenience init(
        bundle: Bundle,
        containerName: String,
        inMemoryOnly: Bool = false
    ) {
        guard let model = Self.getModel(in: bundle, with: containerName) else {
            fatalError("No NSManagedObjectModel found in \(bundle.bundlePath)")
        }

        self.init(model: model, containerName: containerName, inMemoryOnly: inMemoryOnly)
    }

    /// Creates a `DatabaseManager` for a specific `NSManagedObjectModel`
    /// - Parameters:
    ///   - model: The specific model that should be loaded with the `NSPersistentContainer`
    ///   - containerName: The name given to the `NSPersistentContainer`
    ///   - inMemoryOnly: Determines if this database should be created in memory only
    public init(
        model: NSManagedObjectModel,
        containerName: String,
        inMemoryOnly: Bool = false
    ) {
        self.name = containerName

        let container: NSPersistentContainer = {
            let container = NSPersistentContainer(name: containerName, managedObjectModel: model)

            if inMemoryOnly {
                let persistentStoreDescription = NSPersistentStoreDescription()
                persistentStoreDescription.type = NSInMemoryStoreType

                container.persistentStoreDescriptions = [persistentStoreDescription]
            }

            container.loadPersistentStores(completionHandler: { _, error in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }

                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            })

            container.viewContext.automaticallyMergesChangesFromParent = true

            return container
        }()

        self.container = container
    }
}

// Helper Methods
public extension DatabaseManager {
    /// Get's a specific model by name, or all models in the provided bundle
    /// - Parameters:
    ///   - bundle: The `Bundle` containing the `NSManagedObjectModel`
    ///   - name: The name of the `NSMangedObjectModel`. If no value is provided, then an `NSManagedObjectModel`
    ///   will be created containing all of the models in the bundle.
    /// - Returns: The `NSManagedObjectModel` if found
    static func getModel(in bundle: Bundle, with name: String? = nil) -> NSManagedObjectModel? {
        if let name {
            if let bundleURL = bundle.url(forResource: name, withExtension: "momd") {
                return NSManagedObjectModel(contentsOf: bundleURL)
            } else {
                // No model found with that name
                return nil
            }
        } else {
            // Merges all models together within the bundle
            return NSManagedObjectModel.mergedModel(from: [bundle])
        }
    }

    /// Convenience function for automatically putting a fetch request on the appropriate context.
    func fetch<T: NSFetchRequestResult>(
        _ request: NSFetchRequest<T>,
        usingContext context: NSManagedObjectContext? = nil
    ) throws -> [T] {
        return try (context ?? self.getThreadSafeContext()).fetch(request)
    }

    /// Convenience function for getting an appropriate `NSManagedObjectContext` for the current thread.
    func getThreadSafeContext() -> NSManagedObjectContext {
        if Thread.current.isMainThread {
            return self.viewContext
        } else {
            return self.newBackgroundContext()
        }
    }
}
