//
//  AuthManager.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 18/06/25.
//

import Supabase
import Foundation

class AuthManager {
    static let shared = AuthManager()

    private let client = SupabaseManager.shared.client

    private init() {}
    
    struct SupabaseUserInsert: Codable {
        let id: String
        let username: String
        let email: String
        let price_per_cigarette: Double
    }
    
    struct SupabaseUserUpdate: Codable {
        let username: String?
        let email: String?
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        do {
            print("🔐 [AUTH DEBUG] Starting sign-in for email: \(email.prefix(3))***")
            print("🔐 [AUTH DEBUG] Password length: \(password.count)")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            try await client.auth.signIn(email: email, password: password)
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("✅ [AUTH DEBUG] Sign-in successful in \(String(format: "%.2f", timeElapsed))s")
            
        } catch let error as URLError {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - CFAbsoluteTimeGetCurrent()
            print("🌐 [AUTH DEBUG] Network error after \(String(format: "%.2f", timeElapsed))s:")
            print("   - Code: \(error.code.rawValue)")
            print("   - Description: \(error.localizedDescription)")
            print("   - URL: \(error.failingURL?.absoluteString ?? "N/A")")
            
            switch error.code {
            case .timedOut:
                print("   - Type: Request timeout")
            case .notConnectedToInternet:
                print("   - Type: No internet connection")
            case .networkConnectionLost:
                print("   - Type: Connection lost")
            case .cannotFindHost:
                print("   - Type: Cannot find host")
            case .cannotConnectToHost:
                print("   - Type: Cannot connect to host")
            default:
                print("   - Type: Other network error")
            }
            
            throw error
            
        } catch {
            print("❌ [AUTH DEBUG] Authentication error:")
            print("   - Type: \(type(of: error))")
            print("   - Description: \(error.localizedDescription)")
            
            // Try to extract more specific error info
            if let nsError = error as NSError? {
                print("   - Domain: \(nsError.domain)")
                print("   - Code: \(nsError.code)")
                print("   - UserInfo: \(nsError.userInfo)")
            }
            
            // Check for common authentication error patterns
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("invalid") || errorString.contains("wrong") {
                print("   - Likely cause: Invalid credentials")
            } else if errorString.contains("network") || errorString.contains("connection") {
                print("   - Likely cause: Network issue")
            } else if errorString.contains("rate") || errorString.contains("limit") {
                print("   - Likely cause: Rate limiting")
            } else if errorString.contains("timeout") {
                print("   - Likely cause: Request timeout")
            }
            
            throw error
        }
    }

    // MARK: - Sign Out
    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Get Current User
    func getCurrentUser() -> User? {
        return client.auth.currentUser
    }

    // MARK: - Check Auth Status
    func isLoggedIn() -> Bool {
        return client.auth.currentUser != nil
    }
    
    // MARK: - Enhanced User Profile Management
    func insertUserMetadata(
        userId: UUID,
        username: String,
        email: String,
        pricePerCigarette: Double
    ) async throws {
        print("📝 [AUTH MANAGER] Inserting user metadata...")
        print("   - User ID: \(userId)")
        print("   - Username: \(username)")
        print("   - Email: \(email)")
        print("   - Price per cigarette: \(pricePerCigarette)")
        
        let userData = SupabaseUserInsert(
            id: userId.uuidString,
            username: username,
            email: email,
            price_per_cigarette: pricePerCigarette
        )

        do {
            let response = try await SupabaseManager.shared.client
                .from("users")
                .insert(userData)
                .execute()
            
            print("✅ [AUTH MANAGER] User profile created successfully")
            print("📊 [AUTH MANAGER] Insert response: \(response)")
        } catch {
            print("❌ [AUTH MANAGER] Failed to create user profile: \(error.localizedDescription)")
            print("🔍 [AUTH MANAGER] Error details: \(error)")
            throw error
        }
    }
    
    // MARK: - Check User Profile Exists
    func checkUserProfileExists(userId: UUID) async throws -> Bool {
        do {
            let response = try await SupabaseManager.shared.client
                .from("users")
                .select("id")
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Check if response contains data
            let data = response.data
            let jsonData = try JSONSerialization.jsonObject(with: data)
            if let array = jsonData as? [[String: Any]], !array.isEmpty {
                print("✅ [AUTH MANAGER] User profile exists for ID: \(userId)")
                return true
            }
            
            print("❌ [AUTH MANAGER] User profile not found for ID: \(userId)")
            return false
        } catch {
            print("❌ [AUTH MANAGER] Error checking user profile: \(error.localizedDescription)")
            // If we get an error, assume user doesn't exist
            return false
        }
    }
    
    // MARK: - Update User Profile
    func updateUserProfile(
        userId: UUID,
        username: String? = nil,
        email: String? = nil
    ) async throws {
        // Create update data using the Codable struct
        let updateData = SupabaseUserUpdate(
            username: username?.isEmpty == false ? username : nil,
            email: email?.isEmpty == false ? email : nil
        )
        
        do {
            try await SupabaseManager.shared.client
                .from("users")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ [AUTH MANAGER] User profile updated successfully")
        } catch {
            print("❌ [AUTH MANAGER] Failed to update user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get User Profile
    func getUserProfile(userId: UUID) async throws -> SupabaseUserInsert? {
        do {
            let response = try await SupabaseManager.shared.client
                .from("users")
                .select("*")
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Parse the response to get user data
            // Note: This is a simplified implementation
            // In a real app, you'd want to properly decode the response
            return nil
        } catch {
            print("❌ [AUTH MANAGER] Failed to get user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Apple Sign-In Specific Methods
    func handleAppleSignIn(
        userId: UUID,
        appleName: String?,
        appleEmail: String?
    ) async throws {
        print("🔐 [AUTH MANAGER] Starting Apple Sign-In handling for user: \(userId)")
        
        // Check if user profile exists
        let profileExists = try await checkUserProfileExists(userId: userId)
        
        if profileExists {
            print("📝 [AUTH MANAGER] User profile exists, updating with Apple data...")
            // Update existing profile with new Apple information if available
            try await updateUserProfile(
                userId: userId,
                username: appleName,
                email: appleEmail
            )
            
        } else {
            print("🆕 [AUTH MANAGER] Creating new user profile...")
            // Create new profile
            let username = appleName ?? "user_\(userId.uuidString.prefix(8))"
            let email = appleEmail ?? ""
            
            print("📋 [AUTH MANAGER] Creating profile with - Username: \(username), Email: \(email)")
            
            try await insertUserMetadata(
                userId: userId,
                username: username,
                email: email,
                pricePerCigarette: 20.0
            )
            
            // Note: Auth metadata update is not available in Supabase Swift client
            // Display name will be stored in the users table as username
            print("ℹ️ [AUTH MANAGER] Display name stored as username: \(username)")
        }
    }
    

}
