//
//  UserManager.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 18/06/25.
//

import SwiftUI
import Foundation

struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let price_per_cigarette: Double
    let joined_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case price_per_cigarette
        case joined_at
    }
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    // MARK: - AppStorage for Persistence
    @AppStorage("cachedUserProfile") private var cachedUserProfileData: Data = Data()
    @AppStorage("lastProfileFetchTime") private var lastFetchTime: Double = 0
    @AppStorage("isProfileLoaded") private var isProfileLoaded: Bool = false
    
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Cache Configuration
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour in seconds
    
    private init() {
        // Load cached data on initialization
        loadCachedProfile()
    }
    
    // MARK: - Public Methods
    
    /// Loads user profile - uses cache if available and valid, otherwise fetches from server
    func loadUserProfile() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Check if we have valid cached data
        if isProfileLoaded && isCacheValid() {
            print("📱 [USER MANAGER] Using cached profile data")
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        // Fetch fresh data from server
        await fetchUserProfileFromServer()
    }
    
    /// Forces a fresh fetch from server (ignores cache)
    func refreshUserProfile() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        await fetchUserProfileFromServer()
    }
    
    /// Clears all cached user data
    func clearUserData() {
        userProfile = nil
        cachedUserProfileData = Data()
        lastFetchTime = 0
        isProfileLoaded = false
        
        print("🗑️ [USER MANAGER] User data cleared")
    }
    
    /// Updates user profile with new data
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        cacheUserProfile(profile)
        
        print("✅ [USER MANAGER] User profile updated and cached")
    }
    
    // MARK: - Private Methods
    
    private func fetchUserProfileFromServer() async {
        do {
            // Get current user from Supabase Auth
            guard let currentUser = AuthManager.shared.getCurrentUser() else {
                await MainActor.run {
                    errorMessage = "No user logged in"
                    isLoading = false
                }
                return
            }
            
            print("🌐 [USER MANAGER] Fetching profile from server for user: \(currentUser.id)")
            
            // Fetch user profile from users table
            let profile = try await fetchUserProfileFromSupabase(userId: currentUser.id)
            
            await MainActor.run {
                self.userProfile = profile
                self.isLoading = false
                self.errorMessage = nil
            }
            
            // Cache the profile
            cacheUserProfile(profile)
            
            print("✅ [USER MANAGER] Profile fetched and cached successfully")
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
                isLoading = false
                print("❌ [USER MANAGER] Error fetching profile: \(error)")
            }
        }
    }
    
    private func fetchUserProfileFromSupabase(userId: UUID) async throws -> UserProfile {
        let response = try await SupabaseManager.shared.client
            .from("users")
            .select("*")
            .eq("id", value: userId.uuidString)
            .execute()
        
        let data = response.data
        let decoder = JSONDecoder()
        
        // Try to decode as array first (Supabase returns array)
        if let profiles = try? decoder.decode([UserProfile].self, from: data),
           let profile = profiles.first {
            return profile
        }
        
        // If array decoding fails, try single object
        let profile = try decoder.decode(UserProfile.self, from: data)
        return profile
    }
    
    private func cacheUserProfile(_ profile: UserProfile) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            cachedUserProfileData = data
            lastFetchTime = Date().timeIntervalSince1970
            isProfileLoaded = true
            
            print("💾 [USER MANAGER] Profile cached successfully")
        } catch {
            print("❌ [USER MANAGER] Failed to cache profile: \(error)")
        }
    }
    
    private func loadCachedProfile() {
        guard !cachedUserProfileData.isEmpty else {
            print("📱 [USER MANAGER] No cached profile data available")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(UserProfile.self, from: cachedUserProfileData)
            userProfile = profile
            
            print("📱 [USER MANAGER] Cached profile loaded successfully")
        } catch {
            print("❌ [USER MANAGER] Failed to load cached profile: \(error)")
            // Clear invalid cache
            clearUserData()
        }
    }
    
    private func isCacheValid() -> Bool {
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastFetch = currentTime - lastFetchTime
        return timeSinceLastFetch < cacheValidityDuration
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return userProfile?.username ?? "Unknown User"
    }
    
    var displayEmail: String {
        return userProfile?.email ?? "No email"
    }
    
    var displayJoinDate: String {
        guard let joinedAt = userProfile?.joined_at else { return "Unknown" }
        return formatJoinDate(joinedAt)
    }
    
    var displayPricePerCigarette: String {
        guard let price = userProfile?.price_per_cigarette else { return "₹0.00" }
        return String(format: "₹%.2f", price)
    }
    
    // MARK: - Helper Methods
    
    private func formatJoinDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        // Fallback: try ISO8601 format
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        return "Unknown"
    }
} 