import SwiftUI

struct SupabaseUser: Encodable {
    let id: UUID
    let username: String
    let email: String
    let price_per_cigarette: Double
}

struct RegistrationView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var pricePerCigarette = ""

    @State private var errorMessage = ""
    @State private var isLoading = false

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("pricePerCig") private var storedPricePerCig: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Text("👋 Welcome to Puff Puff Pass")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Text("Let’s set you up")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)

                Form {
                    Section(header: Text("Account Info")) {
                        TextField("Username", text: $username)
                            .disableAutocorrection(true)

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        SecureField("Password", text: $password)
                    }

                    Section(header: Text("Preferences")) {
                        TextField("Price per Cigarette", text: $pricePerCigarette)
                            .keyboardType(.decimalPad)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                    }

                    Button(action: {
                        Task { await registerUser() }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            }
                            Text("Register")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top)
                }
            }
        }
    }

    private func registerUser() async {
        errorMessage = ""
        isLoading = true

        // Input Validation
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty, !pricePerCigarette.isEmpty else {
            errorMessage = "All fields are required."
            isLoading = false
            return
        }

        guard let price = Double(pricePerCigarette), price >= 0 else {
            errorMessage = "Enter a valid price per cigarette."
            isLoading = false
            return
        }

        do {
            // Register the user with Supabase Auth
            try await AuthManager.shared.signUp(email: email, password: password)

            // Get current user ID from Supabase Auth
            guard let userId = AuthManager.shared.getCurrentUser()?.id else {
                errorMessage = "Could not retrieve user information after registration."
                isLoading = false
                return
            }

            // Insert user details into your 'users' table
            let newUser = SupabaseUser(
                id: userId,
                username: username,
                email: email,
                price_per_cigarette: price
            )

            try await SupabaseManager.shared.client
                .from("users")
                .insert([newUser])
                .execute()

            // Store locally in AppStorage / UserDefaults
            storedPricePerCig = pricePerCigarette
            UserDefaults.standard.set(username, forKey: "userName")
            UserDefaults.standard.set(email, forKey: "userEmail")
            UserDefaults.standard.set(Date().formatted(date: .long, time: .omitted), forKey: "joinDate")

            isLoggedIn = true
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
