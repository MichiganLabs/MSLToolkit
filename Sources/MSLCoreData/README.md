# MSL Core Data

MSL Core Data provides common helper functions to work with [Core Data.](https://developer.apple.com/documentation/coredata/)
* [Features](#features)
* [Installation](#installation)

## Features
* [x] [DatabaseManager](./documentation/database_manager.md)
* [x] [CoreDataPublisher](./documentation/coredata_publisher.md)

## Installation

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding MSLNetworking as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift` or the Package list in Xcode.

```swift
dependencies: [
    .package(url: "https://github.com/MichiganLabs/MSLToolkit.git", from: "0.0.1")
]
```

Then add the dependency of `MSLCoreData` to your target:

```swift
.product(name: "MSLToolKit", package: "MSLCoreData")
```
