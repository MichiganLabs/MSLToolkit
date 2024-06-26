# MSL XCTest

MSL XCTest provides common helper functions to work with [XCTest.](https://developer.apple.com/documentation/xctest)
* [Features](#features)
* [Installation](#installation)

## Features
* [x] XCTestCase
  * awaitPublished
  * awaitPublisherConvertible
  * Springboard
      * deleteApp
      * getAlert

## Installation

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding MSLXCTest as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift` or the Package list in Xcode.

```swift
dependencies: [
    .package(url: "https://github.com/MichiganLabs/MSLToolkit.git", from: "0.0.1")
]
```

Then add the dependency of `MSLXCTest` to your target:

```swift
.product(name: "MSLToolKit", package: "MSLXCTest")
```
