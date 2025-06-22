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
        try await client.auth.signIn(email: email, password: password)
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
