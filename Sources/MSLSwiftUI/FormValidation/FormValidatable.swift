import SwiftUI

public protocol FormValidatable {
    func isValid() -> Bool

    func hasChanges() -> Bool
}

public extension FormValidatable {
    func isValid() -> Bool {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let field = child.value as? ValidatedProtocol {
                if case .invalid = field.status {
                    return false
                }
            }
        }
        return true
    }

    func hasChanges() -> Bool {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let field = child.value as? ValidatedProtocol {
                if field.editState == .dirty {
                    return true
                }
            }
        }
        return false
    }

    func getNextInvalidProperty() -> String? {
        let mirror = Mirror(reflecting: self)
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

public protocol ValidatedProtocol {
    /// An error message describing why the value provided for the field did not pass validation.
    var errorMessage: String? { get }

    var isRequired: Bool { get }

    var status: FormFieldStatus { get }

    var editState: FormFieldEditState { get }

    mutating func reset()
}
