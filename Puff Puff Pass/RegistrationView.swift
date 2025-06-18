import SwiftUI

struct RegistrationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var pricePerCigarette = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Create your account")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)

                    TextField("Price per Cigarette", text: $pricePerCigarette)
                        .keyboardType(.decimalPad)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button {
                    Task {
                        await register()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }
                        Text("Register")
                    }
                }
            }
            .navigationTitle("Register")
        }
    }

    private func register() async {
        isLoading = true
        errorMessage = ""

        guard !email.isEmpty, !password.isEmpty, !pricePerCigarette.isEmpty else {
            errorMessage = "All fields are required."
            isLoading = false
            return
        }

        guard let _ = Double(pricePerCigarette) else {
            errorMessage = "Enter a valid price."
            isLoading = false
            return
        }

        do {
            try await AuthManager.shared.signUp(email: email, password: password)
            UserDefaults.standard.set(pricePerCigarette, forKey: "pricePerCig")
            isLoggedIn = true
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
