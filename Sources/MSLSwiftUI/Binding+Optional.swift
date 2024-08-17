import SwiftUI

/// Provides a way to default to a non optional type when using bindings
/// https://stackoverflow.com/a/61002589/6437349
public func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
