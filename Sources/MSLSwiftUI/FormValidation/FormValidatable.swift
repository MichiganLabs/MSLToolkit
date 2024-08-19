import SwiftUI

public protocol FormValidatable: KeyPathListable {
    mutating func isValid() -> Bool

    mutating func hasChanges() -> Bool

    mutating func nextInvalidProperty() -> String?
}

public extension FormValidatable {
    mutating func isValid() -> Bool {
        let mirror = self.reflectionCache()
        for child in mirror.children {
            if let field = child.value as? ValidatedProtocol {
                if case .invalid = field.status {
                    return false
                }
            }
        }
        return true
    }

    mutating func hasChanges() -> Bool {
//        for keyPath in Self.allKeyPaths.values {
//            if let field = self[keyPath: keyPath] as? ValidatedProtocol {
//                if field.editState == .dirty {
//                    return true
//                }
//            }
//            print("test")
//        }

        let mirror = self.reflectionCache()
        for child in mirror.children {
            if let field = child.value as? ValidatedProtocol {
                if field.editState == .dirty {
                    return true
                }
            }
        }
        return false
    }

    mutating func nextInvalidProperty() -> String? {
        let mirror = self.reflectionCache()
        for child in mirror.children {
            guard let propertyName = child.label else { continue }

            if let field = child.value as? ValidatedProtocol {
                if case .invalid = field.status {
                    return propertyName
                }
            }
        }
        return nil
    }

    // May need to be a class
//    mutating func reset() {
//        let mirror = Mirror(reflecting: self)
//        for var child in mirror.children {
//            if var field = child.value as? ValidatedProtocol {
//                field.reset()
//
//                // Update the property value
//                if let propertyName = child.label {
//                    let keyPath = \Self.[propertyName]
//                    self[keyPath: keyPath] = field as! Self.[propertyName]
//                }
//            }
//        }
//    }
}

public protocol FormNavigatable {
    static var keyPaths: [String: PartialKeyPath<Self>] { get }
    var nextInvalidProperty: PartialKeyPath<Self>? { get }
}

extension FormNavigatable {
    func nextInvalidProperty() -> PartialKeyPath<Self>? {
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            if let field = child.value as? ValidatedProtocol, case .invalid = field.status {
                return Self.keyPaths[propertyName]
            }
        }
        return nil
    }
}

public protocol ValidatedProtocol {
    /// An error message describing why the value provided for the field did not pass validation.
    var errorMessage: String? { get }

    var isRequired: Bool { get }

    var status: FormFieldStatus { get }

    var editState: FormFieldEditState { get }

    mutating func reset()
}
