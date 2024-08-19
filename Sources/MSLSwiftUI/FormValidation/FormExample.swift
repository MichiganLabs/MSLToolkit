// Field format (i.e add dollar sign to monetary field)
// Field validation (i.e. verify number is between 1 and 10)
// - Prevent users from entering invalid values
// Bindable update

// Required fields

// FormValidation does not handle text formatting. Any text formatting should be
// handled by the view displaying the value from the form object.

// Ideas:
// - Get "next" required/invalid field
// - Restrict value changes if validation fails
// - Dirty / Clean management

import SwiftUI

struct UserFormInfo: FormValidatable {
    @FormFieldValidated(
        requirement: .required(nil),
        validation: { $0.count < 3 ? "Name must be at least 3 characters" : nil }
    )
    var name = ""

    @FormFieldValidated(
        requirement: .required("This field is required"),
        validation: { value in
            !(value?.isPhoneNumberValid() ?? false) ? "Phone number is not valid." : nil
        }
    )
    var phoneNumber: String? = nil

    @FormFieldValidated(validation: { !$0.isEmailValid() ? "Invalid email address" : nil })
    var email = ""

    @FormFieldValidated(validation: { $0.isEmpty ? "Address cannot be empty" : nil })
    var address = ""

    var dateOfBirth = Date()

    var donation: Double? = nil

    mutating func reset() {
        self._name.reset()
    }
}

extension String {
    func isPhoneNumberValid() -> Bool {
        let phoneRegex = "^[0-9+\\- ]{7,15}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: self)
    }

    func isEmailValid() -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
}

struct ExampleForm: View {
    @State
    private var userInfo = UserFormInfo()

    @State
    private var isSubmitted = false

    @State
    private var fieldToFocus: String?

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: self.$userInfo.name)
                        .overlay(
                            ValidationErrorView(errorMessage: self.userInfo.$name.errorMessage),
                            alignment: .bottomLeading
                        )

                    TextField("Phone Number", text: self.$userInfo.phoneNumber ?? "")
                        .keyboardType(.phonePad)
                        .overlay(
                            ValidationErrorView(errorMessage: self.userInfo.$phoneNumber.errorMessage),
                            alignment: .bottomLeading
                        )

                    TextField("Email", text: self.$userInfo.email)
                        .keyboardType(.emailAddress)
                        .overlay(ValidationErrorView(errorMessage: self.userInfo.$email.errorMessage))

                    TextField("Address", text: self.$userInfo.address)
                        .overlay(ValidationErrorView(errorMessage: self.userInfo.$address.errorMessage))

                    DatePicker("Date of Birth", selection: self.$userInfo.dateOfBirth, displayedComponents: .date)
                }
            }

            Button("Submit") {
                // Handle submit action
                self.isSubmitted = true
            }
            .disabled(!self.userInfo.isValid())

            Button("Jump To Field") {
//                self.fieldToFocus = self.userInfo.getNextInvalidProperty()
            }

            Button("Reset") {
                self.userInfo.reset()
//                self.userInfo.reset()
            }

            if let field = self.fieldToFocus {
                Text(field)
            }

            if self.userInfo.hasChanges() {
                Text("Has Changes!")
            }

            if self.isSubmitted {
                Text("Submitted!")
            }
        }
    }
}

struct ValidationErrorView: View {
    var errorMessage: String?

    var body: some View {
        Group {
            if let errorMessage = self.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    ExampleForm()
}
