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
    @State private var loadingMessage = "Signing in..."
    
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
                
                // Move the sign-in section to the center of the bottom half
                Spacer()
                
                VStack(spacing: 14) {
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
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            Text(loadingMessage)
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .transition(.opacity)
                        }
                        .padding(.top, 8)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 0)
                .padding(.bottom, 0)
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
                .frame(height: 220)
                .background(Color.clear)
                .alignmentGuide(.bottom) { d in d[.bottom] }
                
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
        loadingMessage = "Authenticating with Apple..."
        
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
            
            // Update loading message for Supabase authentication
            await MainActor.run {
                loadingMessage = "Signing in to your account..."
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
                
                // Update loading message for profile creation
                await MainActor.run {
                    loadingMessage = "Setting up your profile..."
                }
                
                // Create user profile in users table
                await createUserProfile(user: user, appleName: name, appleEmail: email)
                
                // Final loading message
                await MainActor.run {
                    loadingMessage = "Welcome! Redirecting..."
                }
                
                // Small delay to show the welcome message
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
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
    
    // MARK: - Create User Profile
    private func createUserProfile(user: User, appleName: String, appleEmail: String?) async {
        do {
            // Determine username: use Apple name if available, otherwise use email prefix
            let username: String
            if !appleName.isEmpty {
                username = appleName
            } else if let email = appleEmail {
                username = String(email.split(separator: "@").first ?? "user")
            } else {
                username = "user_\(user.id.uuidString.prefix(8))"
            }
            
            // Use the email from Supabase user or fallback to Apple email
            let finalEmail = user.email ?? appleEmail ?? ""
            
            // Create user profile with default price_per_cigarette = 20
            try await AuthManager.shared.insertUserMetadata(
                userId: user.id,
                username: username,
                email: finalEmail,
                pricePerCigarette: 20.0
            )
            
            print("✅ User profile created successfully for user: \(username)")
            
        } catch {
            // Log the error but don't fail the login process
            print("⚠️ Failed to create user profile: \(error.localizedDescription)")
            print("⚠️ User is still logged in, but profile creation failed")
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
