#  CoreDataPublisher

## Why Use?
When designing your architecture to have distinct separate layers (like in the Clean Architecture Pattern), you may find yourself struggling to react to changes in your database layer without exposing CoreData specific dependencies to the other layers.

With this in mind, `CoreDataPublisher` is designed to abstract away the underlying CoreData requirements for data observation (i.e. `NSFetchedResultsController`) and expose a stream of data for observers to consume.

## How to Use
An unfortunate consequence of needing to use `NSFetchedResultsController` to observe changes in CoreData is that we need to maintain a reference to our `NSFetchedResultsController`, otherwise it will get deallocated and our observation will fail.

To do this while also aiming to abstract away the interworkings of CoreData, we recommend the use of `DataStore` from the `MSLFoundation` package which will allow us to completely hide the CoreData complexities and maintain a reference to the underlying `NSFetchedResultController` through the `CoreDataPublisher`. 

Further more, since we don't want to expose our Entity object from our CoreData layer to other layers of our application, we'll need to have a common model defined and a way to convert our Entity  to this model. To accomplish this, we just need to have our Entity model conform to the `ModelConvertible` protocol and implement the required function.

 Let's dive into an example of how we might set all of this up. For demonstration purposes, let's also assume we are trying to follow the Clean Architecture pattern.

### Step 1: Add `ModelConvertible` Conformance
This protocol conformance ensures that the `CoreDataPublisher` can convert our Entity object to a common model object that other layers of our application can access. In this way, we can keep our Entity object as `internal`ly scoped to a specific layer.

```swift
extension MyEntity: ModelConvertible {
    func toModel() -> MySharedModel {
        return MySharedModel(
            name: self.name,
            age: self.age,
        )
    }
}

```


### Step 2: Building a DataStore
A Repository in the Data Layer is a great place for us to build and return a DataStore.

```swift
func buildDataStore() -> DataStore<[MySharedModel]> {
    let fetch = // build a NSFetchRequest
    
    let context = // get NSManagedObjectContext (use `viewContext` if the data is intended to drive UI)

    let controller = NSFetchedResultsController(
      fetchRequest: fetch,
      managedObjectContext: context,
      sectionNameKeyPath: nil,
      cacheName: nil
    )

    let publisher = DataStorePublisher<MyEntity>(
        fetchedRequestController: controller
    )

    return DataStore(publisher)
}
```

### Step 3: Subscribing to the DataStore
Now that we can access our DataStore through our Repository, in the Presentation Layer, we simply retrieve and retain the DataStore to start observing it's published values.

```swift
class ViewModel: ObservableObject {
    private var dataStore: DataStore<[MySharedModel]>

    init(repo: MyRepositoryInterface) {
        // Retaining the DataStore is critical in order for the subscription to function
        self.dataStore = repo.buildDataStore()

        // Observe the patient case of interest
        self.dataStore.publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { values in
                // TODO: Use those models!
            })
            .store(in: &self.cancellables)
    }
}
```

