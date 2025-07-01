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
    
    func insertUserMetadata(
        userId: UUID,
        username: String,
        email: String,
        pricePerCigarette: Double
    ) async throws {
        let userData = SupabaseUserInsert(
            id: userId.uuidString,
            username: username,
            email: email,
            price_per_cigarette: pricePerCigarette
        )

        try await SupabaseManager.shared.client
            .from("users")
            .insert(userData)
            .execute()
    }

}
