import SwiftUI

public enum FormFieldRequirement: Equatable {
    /// Provide an optional message when a value is not provided
    case required(_ message: String?)

    /// A value is not required for this field
    case optional
}

public enum FormFieldStatus: Equatable {
    /// No value has been provided
    case empty

    /// A value has been provided, but it did not pass validation
    case invalid(message: String?)

    /// A value has been provided and it passed validation
    case valid
}

public enum FormFieldEditState {
    case pristine
    case dirty
}

@propertyWrapper
public struct FormFieldValidated<Value: Equatable>: ValidatedProtocol {
    private var value: Value
    private let validation: (Value) -> String?
    private let requirement: FormFieldRequirement

    private let originalValue: Value

    public private(set) var status: FormFieldStatus

    public var editState: FormFieldEditState {
        if self.value != self.originalValue {
            return .dirty
        } else {
            return .pristine
        }
    }

    public var errorMessage: String? {
        if case let .invalid(message) = self.status {
            return message
        } else {
            return nil
        }
    }

    public var isRequired: Bool {
        if case .required = self.requirement {
            return true
        } else {
            return false
        }
    }

    public mutating func reset() {
        self.wrappedValue = self.originalValue
    }

    public var wrappedValue: Value {
        get { self.value }
        set {
            // If the value is an optional String and the new value is an empty string, set it to nil
            if
                isOptional(Value.self),
                let stringValue = newValue as? String,
                stringValue.isEmpty == true
            {
                // Assign to `nil` when string is empty
                // swiftlint:disable:next force_cast
                self.value = assignNilIfEmpty(stringValue) as! Value
            } else {
                self.value = newValue
            }

            let validationResult = self.validation(self.value)
            self.status = Self.calculateStatus(
                requirement: self.requirement,
                value: self.value,
                validationResult: validationResult
            )
        }
    }

    // When using $, returns the instance of this `FormFieldValidated` class
    public var projectedValue: FormFieldValidated<Value> {
        return self
    }

    public init(
        wrappedValue: Value,
        _ requirement: FormFieldRequirement = .optional,
        validation: @escaping (Value) -> String? = { _ in return nil }
    ) {
        self.originalValue = wrappedValue

        self.requirement = requirement
        self.value = wrappedValue
        self.validation = validation

        let validationResult = validation(wrappedValue)
        self.status = Self.calculateStatus(
            requirement: requirement,
            value: wrappedValue,
            validationResult: validationResult
        )
    }
}

// MARK: Helper functions

extension FormFieldValidated {
    private static func calculateStatus(
        requirement: FormFieldRequirement,
        value: Value,
        validationResult: String?
    ) -> FormFieldStatus {
        if self.isNilOrEmpty(value) {
            if case let .required(message) = requirement {
                return .invalid(message: message)
            } else {
                return .empty
            }
        }

        if let message = validationResult {
            return .invalid(message: message)
        }

        return .valid
    }

    private func assignNilIfEmpty<T>(_ value: T) -> T? {
        if let stringValue = value as? String, stringValue.isEmpty {
            return nil
        }
        return value
    }

    private static func isNilOrEmpty(_ value: Value) -> Bool {
        if let unwrappedValue = value as? AnyOptional, unwrappedValue.isNil {
            return true
        } else if (value as? String)?.isEmpty == true {
            return true
        } else {
            return false
        }
    }
}
