#  DatabaseManager

## Features
`DatabaseManager` allows you to quickly and easily setup a `NSPersistentContainer` with your predefined `.xcdatamodeld`s. At it's simplest, you can create an instance of `DatabaseManager` in just a single line of code that will automatically load all models in the provided bundle.

```swift
let database = DatabaseManager(bundle: .module, containerName: "MyDatabaseInstance")
``` 

> **_Pro Tip:_**  If you are making unit/ui tests, make use of the `inMemoryOnly` argument so that data is not persisted between tests 🎉 


With your database instantiated, you can now easily get access to the `viewContext`, create background contexts, make `fetch` requests, and more.
