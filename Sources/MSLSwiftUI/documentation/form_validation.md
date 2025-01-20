# Form Validation

## Features
* Validate forms quickly and easily through the use of property wrappers
* Mark fields as required / options
* Add custom validation logic for each field
* Add custom error / validation messages
* Know if a field is `pristine` or `dirty`.

## How to Use
The following steps describe how to quickly setup a form and validation for a SwiftUI view.
An example implementation has also been created in the `FormExample.swift` file. 

### Step 1: Create a form backing struct

```swift
struct UserFormInfo: FormValidatable {
    var name: String = ""
    var phoneNumber: String? = nil
    var email: String = ""
}
```

### Step 2: Add `FormValidatable` conformance

```swift
struct UserFormInfo: FormValidatable {
    // ...
}
```

### Step 3: Add property wrappers

```swift
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
}
```

### Step 4: Connect to your UI

```swift
struct ExampleForm: View {
    @State
    private var userInfo = UserFormInfo()

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
                }
            }
            
            Button("Submit") {
                // Handle submit action
            }
            .disabled(!self.userInfo.isValid())
            
            Button("Reset") {
                self.userInfo = UserFormInfo()
            }
        }
    }
}
