import SwiftUI

struct RegistrationView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var pricePerCigarette = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Account")
                            .font(.largeTitle).bold()
                        Text("Join us to track your journey 💪")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)

                    // Input Fields
                    Group {
                        CustomTextField("Username", text: $name)
                        CustomTextField("Email", text: $email, keyboardType: .emailAddress)
                        SecureField("Password (min 6 chars)", text: $password)
                            .textFieldStyle(StyledField())
                        CustomTextField("Price per Cigarette", text: $pricePerCigarette, keyboardType: .decimalPad)
                    }

                    // Register Button
                    Button(action: handleRegister) {
                        Text("Register")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func handleRegister() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showValidationError("Please enter your name.")
            return
        }

        guard isValidEmail(email) else {
            showValidationError("Please enter a valid email address.")
            return
        }

        guard password.count >= 6 else {
            showValidationError("Password must be at least 6 characters.")
            return
        }

        guard let price = Double(pricePerCigarette), price >= 0 else {
            showValidationError("Enter a valid price per cigarette.")
            return
        }

        // Save to UserDefaults
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(password, forKey: "userPassword")
        UserDefaults.standard.set(pricePerCigarette, forKey: "pricePerCig")
        UserDefaults.standard.set(Date().formatted(date: .long, time: .omitted), forKey: "joinDate")
        
        isLoggedIn = true
    }

    private func showValidationError(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}

// MARK: - Custom Components

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    init(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(StyledField())
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}

struct StyledField: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }
}
