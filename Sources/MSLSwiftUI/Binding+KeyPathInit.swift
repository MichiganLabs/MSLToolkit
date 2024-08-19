import SwiftUI

extension Binding {
    /**
     A convenience initializer for creating a `Binding` instance from a parent object and a writable key path.

     This initializer allows you to create a `Binding` that reads and writes to a specific property of a parent object.

     - Parameters:
       - parent: The parent object containing the property to bind to.
       - keyPath: A writable key path from the parent object to the property of type `Value`.

     - Example:
     ```swift
     struct Parent {
       var childProperty: String
     }

     let parent = Parent(childProperty: "Initial Value")
     let binding = Binding(parent, keyPath: \.childProperty)

     // Now `binding` can be used to read and write `parent.childProperty`
     binding.wrappedValue = "New Value"
     print(parent.childProperty) // Prints "New Value"
     ```
     **/
    init<Parent>(_ parent: Parent, keyPath: WritableKeyPath<Parent, Value>) {
        self.init(
            get: {
                return parent[keyPath: keyPath]
            }, set: {
                var parent = parent
                parent[keyPath: keyPath] = $0
            }
        )
    }
}
