func isOptional(_ type: (some Any).Type) -> Bool {
    return type is OptionalProtocol.Type
}

protocol OptionalProtocol {}
extension Optional: OptionalProtocol {}

protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { return self == nil }
}
