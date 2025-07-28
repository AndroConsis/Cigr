import SwiftUI
import AuthenticationServices

struct CigrLoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showTerms = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userName") private var userName = ""
    @AppStorage("appleUserId") private var appleUserId = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.20, blue: 0.40), // deep navy
                    Color(red: 0.30, green: 0.20, blue: 0.50)  // muted purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer(minLength: 60)
                
                // App name
                Text("Cigr")
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .accessibilityAddTraits(.isHeader)
                
                // Subtitle
                Text("Track with awareness. Start your journey.")
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Lower part: Sign in with: + full button
                VStack(spacing: 18) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.bottom, 2)
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    let userIdentifier = appleIDCredential.user
                                    let email = appleIDCredential.email
                                    let fullName = appleIDCredential.fullName
                                    let name = [fullName?.givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                                    
                                    // Save to AppStorage
                                    appleUserId = userIdentifier
                                    if let email = email { userEmail = email }
                                    if !name.isEmpty { userName = name }
                                    
                                    // Call Supabase sign in/up with Apple
                                    handleAppleSignIn(userIdentifier: userIdentifier, email: email, name: name)
                                }
                            case .failure(let error):
                                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 54)
                    .frame(maxWidth: 340)
                    .cornerRadius(12)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Sign in with Apple")
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.bottom, 120)
                
                Spacer()
                
                // Footer
                VStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, -2)
                    
                    Button(action: { showTerms = true }) {
                        Text("Terms & Conditions")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .underline()
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .sheet(isPresented: $showTerms) {
                        SafariView(url: URL(string: "https://your-terms-url.com")!)
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Supabase Apple Sign In Handler
    func handleAppleSignIn(userIdentifier: String, email: String?, name: String) {
        // 1. Exchange Apple credential for a Supabase session (using Supabase Auth)
        // 2. If first sign-in, register user in your users table
        // 3. On success, set isLoggedIn = true
        Task {
            do {
                // Use Supabase Auth to sign in with Apple (this requires backend setup for Apple provider)
                // Example (pseudo-code, replace with your actual Supabase client call):
                // let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(provider: .apple, idToken: <appleIDToken>, nonce: <nonce>)
                // For now, just simulate success:
                isLoggedIn = true
                // Optionally, insert user into your users table if needed
            } catch {
                errorMessage = "Supabase sign in failed: \(error.localizedDescription)"
            }
        }
    }
}

// Helper for showing Terms in Safari
import SafariServices
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct CigrLoginView_Previews: PreviewProvider {
    static var previews: some View {
        CigrLoginView()
            .preferredColorScheme(.dark)
        CigrLoginView()
            .preferredColorScheme(.light)
    }
} 