public extension Collection {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
}

public extension Optional where Wrapped: Collection {
    var isEmptyOrNil: Bool {
        return self?.isEmpty ?? true
    }
}
