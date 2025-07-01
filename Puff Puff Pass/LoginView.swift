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
    @State private var showPassword = false
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue.gradient)
                                .padding(.top, 40)
                            
                            Text("Welcome Back")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Sign in to your account")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 40)
                        
                        // Form Section
                        VStack(spacing: 24) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(isEmailFocused ? .blue : .gray)
                                        .frame(width: 20)
                                    
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .textContentType(.emailAddress)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isEmailFocused = true
                                                isPasswordFocused = false
                                            }
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isEmailFocused ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                                .animation(.easeInOut(duration: 0.2), value: isEmailFocused)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(isPasswordFocused ? .blue : .gray)
                                        .frame(width: 20)
                                    
                                    Group {
                                        if showPassword {
                                            TextField("Password", text: $password)
                                        } else {
                                            SecureField("Password", text: $password)
                                        }
                                    }
                                    .textContentType(.password)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isPasswordFocused = true
                                            isEmailFocused = false
                                        }
                                    }
                                    
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isPasswordFocused ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                                .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
                            }
                            
                            // Error Message
                            if let message = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .accessibilityLabel("Login error: \(message)")
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(.spring(response: 0.3), value: errorMessage)
                            }
                            
                            // Login Button
                            Button(action: {
                                // Dismiss keyboard
                                hideKeyboard()
                                
                                Task {
                                    await handleLogin()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.right")
                                    }
                                    
                                    Text(isLoading ? " Logging in..." : "Login")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            isLoading || !canLogin
                                            ? Color.gray.gradient
                                            : Color.blue.gradient
                                        )
                                )
                            }
                            .disabled(isLoading || !canLogin)
                            .animation(.easeInOut(duration: 0.2), value: isLoading)
                            .animation(.easeInOut(duration: 0.2), value: canLogin)
                            
                            // Registration Link
                            NavigationLink(destination: RegistrationView()) {
                                HStack {
                                    Text("New user?")
                                        .foregroundColor(.secondary)
                                    
                                    Text("Register here")
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                .font(.subheadline)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
            .onTapGesture {
                hideKeyboard()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEmailFocused = false
                    isPasswordFocused = false
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Handle Login Logic (Your existing logic - unchanged)
    func handleLogin() async {
        errorMessage = nil
        
        guard validateInputs() else { return }
        
        isLoading = true
        
        do {
            try await AuthManager.shared.signIn(email: email, password: password)
            
            // ✅ Successfully logged in
            isLoggedIn = true
            
        } catch {
            await handleLoginError(error)
        }
        
        isLoading = false
    }

    private func handleLoginError(_ error: Error) async {
        // Handle network timeout specifically
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                errorMessage = "Request timed out. Please check your connection and try again."
                // Auto-retry after a delay
//                await performAutoRetry()
                return
                
            case .notConnectedToInternet, .networkConnectionLost:
                errorMessage = "No internet connection. Please check your network and try again."
                return
                
            case .cannotFindHost, .cannotConnectToHost:
                errorMessage = "Cannot connect to server. Please try again later."
                return
                
            default:
                break
            }
        }
        
        enum AuthError: Error {
            case invalidCredentials
            case accountLocked
            case tooManyAttempts
            case serverError
            case networkError
            case unknown
        }
        
        // Handle authentication-specific errors
        if let authError = error as? AuthError {
            switch authError {
            case .invalidCredentials:
                errorMessage = "Invalid email or password. Please try again."
            case .accountLocked:
                errorMessage = "Account temporarily locked. Please try again later."
            case .tooManyAttempts:
                errorMessage = "Too many login attempts. Please wait before trying again."
            default:
                errorMessage = "Login failed. Please check your credentials and try again."
            }
            return
        }
        
        // Generic fallback for other errors
        errorMessage = "Login failed. Please check your credentials and try again."
    }

    private func performAutoRetry() async {
        // Wait 2 seconds before auto-retry
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Only retry if user hasn't navigated away or started another login
        guard isLoading else { return }
        
        await handleLogin()
    }

    // Alternative: Manual retry with user confirmation
    private func offerRetryForTimeout() {
        // You could show an alert with retry option instead of auto-retry
        // This gives users more control over the retry behavior
    }

    // MARK: - Input Validation (Your existing logic - unchanged)
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
