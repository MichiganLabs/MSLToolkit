/// A protocol that defines a buildable type.
public protocol Buildable {
    associatedtype T
    
    /// Builds and returns an instance of type `T`.
    func build() -> T
}

public extension Buildable {
    /// Sets a value for a given key path.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property to set.
    ///   - value: The value to set for the property.
    /// - Returns: A copy of the object with the updated property.
    func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
    
    /// Sets a value for a given key path using a function.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property to set.
    ///   - function: A function that returns the value to set for the property.
    /// - Returns: A copy of the object with the updated property.
    func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ function: () -> Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = function()
        return copy
    }
    
    /// Adds an element to a collection property for a given key path.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the collection property to add to.
    ///   - value: The element to add to the collection.
    /// - Returns: A copy of the object with the updated collection property.
    func add<PropertyType: RangeReplaceableCollection>(_ keyPath: WritableKeyPath<Self, PropertyType>, _ value: PropertyType.Element) -> Self {
        var copy = self
        copy[keyPath: keyPath].append(value)
        return copy
    }
    
    /// Adds an element to a collection property for a given key path using a function.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the collection property to add to.
    ///   - function: A function that returns the element to add to the collection.
    /// - Returns: A copy of the object with the updated collection property.
    func add<PropertyType: RangeReplaceableCollection>(_ keyPath: WritableKeyPath<Self, PropertyType>, _ function: () -> PropertyType.Element) -> Self {
        var copy = self
        copy[keyPath: keyPath].append(function())
        return copy
    }
}
