//
//  LoginView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    @State private var errorMessage: String?
    @State private var isLoading = false

    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Logging in...")
                        .padding(.top)
                }

                Form {
                    Section(header: Text("Login")) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.emailAddress)

                        SecureField("Password", text: $password)
                    }

                    if let message = errorMessage {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                            .accessibilityLabel("Login error: \(message)")
                    }

                    Button("Login") {
                        Task {
                            await handleLogin()
                        }
                    }
                    .disabled(isLoading)
                }

                NavigationLink("New user? Register here", destination: RegistrationView())
                    .padding(.bottom)
            }
            .navigationTitle("Login")
        }
    }

    // MARK: - Handle Login Logic
    func handleLogin() async {
        errorMessage = nil

        guard validateInputs() else { return }

        isLoading = true
        do {
            try await AuthManager.shared.signIn(email: email, password: password)

            // ✅ Successfully logged in
            isLoggedIn = true
        } catch {
            // OWASP-aligned: generic message avoids account enumeration
            errorMessage = "Login failed. Please check your credentials and try again."
        }

        isLoading = false
    }

    // MARK: - Input Validation
    func validateInputs() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Email and password are required."
            return false
        }

        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address."
            return false
        }

        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters long."
            return false
        }

        return true
    }

    func isValidEmail(_ email: String) -> Bool {
        // Simple regex for email validation
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}

