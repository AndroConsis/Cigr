import SwiftUI
import Auth
import AuthenticationServices
import Foundation
import CryptoKit

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
    @State private var currentNonce: String?
    
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
                
                // App icon
                Image("cigr_app_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 16)
                    .accessibilityLabel("Cigr app logo")
                
                // App name
                Text("Cigr")
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .padding(.top, 8)
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
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.bottom, 2)
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            // Generate nonce for security
                            currentNonce = randomNonceString(length: 32)
                            request.nonce = sha256(currentNonce!)
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                await handleAppleSignInResult(result)
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
                            .padding(.horizontal, 24)
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
    
    // MARK: - Security Helpers
    private func randomNonceString(length: Int) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                 if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Enhanced Apple Sign In Handler
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                await MainActor.run {
                    errorMessage = "Failed to get Apple credentials"
                }
                return
            }
            
            Task {
                print("🔑 [APPLE SIGN IN] Credential: \(appleIDCredential)")
                await signInWithApple(credential: appleIDCredential)
            }
            
        case .failure(let error):
            await MainActor.run {
                handleAppleSignInError(error)
            }
        }
    }
    
    private func handleAppleSignInError(_ error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                // User canceled - no need to show error
                return
            case .failed:
                errorMessage = "Apple Sign In failed. Please try again."
            case .invalidResponse:
                errorMessage = "Invalid response from Apple. Please try again."
            case .notHandled:
                errorMessage = "Sign In request not handled. Please try again."
            case .unknown:
                errorMessage = "An unknown error occurred. Please try again."
            @unknown default:
                errorMessage = "Apple Sign In failed. Please try again."
            }
        } else {
            errorMessage = "Apple Sign In failed. Please try again."
        }
    }
    
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            loadingMessage = "Authenticating with Apple..."
        }
        
        do {
            // Extract user data
            let userIdentifier = credential.user
            let email = credential.email
            let fullName = credential.fullName
            
            // Parse name components safely
            let name = parseAppleFullName(fullName)
            
            // Verify nonce for security
            guard let nonce = currentNonce else {
                await MainActor.run {
                    errorMessage = "Security verification failed. Please try again."
                    isLoading = false
                }
                return
            }
            
            // Save to AppStorage (only if we have new data)
            appleUserId = userIdentifier
            if let email = email { userEmail = email }
            if !name.isEmpty { userName = name }
            
            print("🔐 [APPLE AUTH] User ID: \(userIdentifier)")
            print("🔐 [APPLE AUTH] Email: \(email ?? "nil")")
            print("🔐 [APPLE AUTH] Name: \(name)")
            
            // Get the identity token as string
            guard let identityToken = credential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                await MainActor.run {
                    errorMessage = "Failed to get Apple identity token"
                    isLoading = false
                }
                return
            }
            
            // Update loading message for Supabase authentication
            await MainActor.run {
                loadingMessage = "Signing in to your account..."
            }
            
            // Sign in with Supabase using Apple ID token with nonce verification
            let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idTokenString,
                    nonce: nonce
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
                
                // Create or update user profile in users table
                await createOrUpdateUserProfile(user: user, appleName: name, appleEmail: email)
                
                // Final loading message
                await MainActor.run {
                    loadingMessage = "Welcome! Redirecting..."
                }
                
                // Small delay to show the welcome message
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Set login state
                await MainActor.run {
                    isLoggedIn = true
                    isLoading = false
                }
                
                print("✅ [APPLE AUTH] Sign in successful for user: \(user.id)")
                
            } else {
                await MainActor.run {
                    errorMessage = "Failed to get user from Supabase session"
                    isLoading = false
                }
            }
            
        } catch {
            await MainActor.run {
                handleSupabaseError(error)
                isLoading = false
            }
        }
    }
    
    // MARK: - Name Parsing Helper
    private func parseAppleFullName(_ fullName: PersonNameComponents?) -> String {
        guard let fullName = fullName else { return "" }
        
        var nameComponents: [String] = []
        
        if let givenName = fullName.givenName?.trimmingCharacters(in: .whitespacesAndNewlines) {
            nameComponents.append(givenName)
        }
        
        if let familyName = fullName.familyName?.trimmingCharacters(in: .whitespacesAndNewlines) {
            nameComponents.append(familyName)
        }
        
        return nameComponents.joined(separator: " ")
    }
    
    // MARK: - Enhanced Error Handling
    private func handleSupabaseError(_ error: Error) {
        print("❌ [SUPABASE AUTH] Error: \(error.localizedDescription)")
    }
    
    // MARK: - Enhanced User Profile Management
    private func createOrUpdateUserProfile(user: User, appleName: String, appleEmail: String?) async {
        do {
            print("🔄 [PROFILE] Starting user profile management...")
            print("   - User ID: \(user.id)")
            print("   - Apple Name: \(appleName)")
            print("   - Apple Email: \(appleEmail ?? "nil")")
            
            // Use the enhanced AuthManager method for Apple Sign-In
            try await AuthManager.shared.handleAppleSignIn(
                userId: user.id,
                appleName: appleName.isEmpty ? nil : appleName,
                appleEmail: appleEmail
            )
            
            print("✅ [PROFILE] User profile managed successfully for user: \(user.id)")
            
        } catch {
            // Log the error but don't fail the login process
            print("⚠️ [PROFILE] Failed to manage user profile: \(error.localizedDescription)")
            print("⚠️ [PROFILE] Error details: \(error)")
            print("⚠️ [PROFILE] User is still logged in, but profile management failed")
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
