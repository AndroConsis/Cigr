import SwiftUI
import Auth
import AuthenticationServices
import Foundation

struct CigrLoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showTerms = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userName") private var userName = ""
    @AppStorage("appleUserId") private var appleUserId = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
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
                            handleAppleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 54)
                    .frame(maxWidth: 340)
                    .cornerRadius(12)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Sign in with Apple")
                    .disabled(isLoading)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
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
    
    // MARK: - Simplified Apple Sign In Handler
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Failed to get Apple credentials"
                return
            }
            
            Task {
                await signInWithApple(credential: appleIDCredential)
            }
            
        case .failure(let error):
            errorMessage = "Apple Sign In failed. Please try again."
        }
    }
    
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Extract user data
            let userIdentifier = credential.user
            let email = credential.email
            let fullName = credential.fullName
            let name = [fullName?.givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            
            // Save to AppStorage
            appleUserId = userIdentifier
            if let email = email { userEmail = email }
            if !name.isEmpty { userName = name }
            
            // Get the identity token as string
            guard let identityToken = credential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                errorMessage = "Failed to get Apple identity token"
                isLoading = false
                return
            }
            
            // Sign in with Supabase using Apple ID token (without nonce)
            let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idTokenString
                )
            )
            
            // Handle successful sign in
            if let user = session.user as? User {
                // Update AppStorage with user info from Supabase
                if let userEmail = user.email {
                    self.userEmail = userEmail
                }
                
                // Set login state
                isLoggedIn = true
            } else {
                errorMessage = "Failed to get user from Supabase session"
            }
            
        } catch {
            errorMessage = "Sign in failed: Please try again."
            print("Sign in failed: \(error.localizedDescription)")
        }
        
        isLoading = false
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
