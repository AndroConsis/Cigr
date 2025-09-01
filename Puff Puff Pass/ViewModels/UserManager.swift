//
//  UserManager.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 18/06/25.
//

import SwiftUI
import Foundation
import CoreLocation
import Supabase

struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let price_per_cigarette: Double
    let currency_code: String?
    let country_code: String?
    let joined_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case price_per_cigarette
        case currency_code
        case country_code
        case joined_at
    }
}

// MARK: - Price Management
struct PriceInfo {
    let countryCode: String
    let currencyCode: String
    let packPrice: Double
    let singlePrice: Double
    let cigarettesPerPack: Int
    let priceType: PriceType
    let lastUpdated: Date
}

enum PriceType {
    case packBased
    case singleBased
}

class PriceManager: ObservableObject {
    static let shared = PriceManager()
    
    @Published var currentPriceInfo: PriceInfo?
    @Published var availablePrices: [PriceInfo] = []
    
    private init() {
        loadDefaultPrices()
    }
    
    // MARK: - Default Prices (Based on 2024 average prices)
    
    private func loadDefaultPrices() {
        availablePrices = [
            // United States - Pack based
            PriceInfo(countryCode: "US", currencyCode: "USD", packPrice: 8.50, singlePrice: 0.85, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // India - Single based (loose cigarettes common)
            PriceInfo(countryCode: "IN", currencyCode: "INR", packPrice: 200.0, singlePrice: 8.0, cigarettesPerPack: 20, priceType: .singleBased, lastUpdated: Date()),
            
            // United Kingdom - Pack based
            PriceInfo(countryCode: "GB", currencyCode: "GBP", packPrice: 12.50, singlePrice: 0.63, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // European Union - Pack based
            PriceInfo(countryCode: "EU", currencyCode: "EUR", packPrice: 7.50, singlePrice: 0.38, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // Canada - Pack based
            PriceInfo(countryCode: "CA", currencyCode: "CAD", packPrice: 15.00, singlePrice: 0.75, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // Australia - Pack based
            PriceInfo(countryCode: "AU", currencyCode: "AUD", packPrice: 25.00, singlePrice: 1.25, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // Japan - Pack based
            PriceInfo(countryCode: "JP", currencyCode: "JPY", packPrice: 500.0, singlePrice: 25.0, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // China - Single based (loose cigarettes common)
            PriceInfo(countryCode: "CN", currencyCode: "CNY", packPrice: 25.0, singlePrice: 1.5, cigarettesPerPack: 20, priceType: .singleBased, lastUpdated: Date()),
            
            // Brazil - Pack based
            PriceInfo(countryCode: "BR", currencyCode: "BRL", packPrice: 8.0, singlePrice: 0.40, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // Mexico - Pack based
            PriceInfo(countryCode: "MX", currencyCode: "MXN", packPrice: 60.0, singlePrice: 3.0, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // Singapore - Pack based
            PriceInfo(countryCode: "SG", currencyCode: "SGD", packPrice: 12.0, singlePrice: 0.60, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // Hong Kong - Pack based
            PriceInfo(countryCode: "HK", currencyCode: "HKD", packPrice: 50.0, singlePrice: 2.5, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // New Zealand - Pack based
            PriceInfo(countryCode: "NZ", currencyCode: "NZD", packPrice: 30.0, singlePrice: 1.5, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // Switzerland - Pack based
            PriceInfo(countryCode: "CH", currencyCode: "CHF", packPrice: 9.0, singlePrice: 0.45, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date()),
            
            // South Korea - Pack based
            PriceInfo(countryCode: "KR", currencyCode: "KRW", packPrice: 4500.0, singlePrice: 225.0, cigarettesPerPack: 20, priceType: .packBased, lastUpdated: Date())
        ]
    }
    
    // MARK: - Price Detection and Management
    
    func getDefaultPrice(for countryCode: String, currencyCode: String) -> PriceInfo? {
        // First try exact country match
        if let exactMatch = availablePrices.first(where: { $0.countryCode == countryCode }) {
            return exactMatch
        }
        
        // Fallback to currency match
        if let currencyMatch = availablePrices.first(where: { $0.currencyCode == currencyCode }) {
            return currencyMatch
        }
        
        // Final fallback to USD
        return availablePrices.first(where: { $0.currencyCode == "USD" })
    }
    
    func getRecommendedPrice(for countryCode: String, currencyCode: String) -> Double {
        guard let priceInfo = getDefaultPrice(for: countryCode, currencyCode: currencyCode) else {
            return 1.0 // Default fallback
        }
        
        // Return the appropriate price based on the country's typical selling method
        return priceInfo.priceType == .singleBased ? priceInfo.singlePrice : priceInfo.singlePrice
    }
    
    func getPriceType(for countryCode: String, currencyCode: String) -> PriceType {
        guard let priceInfo = getDefaultPrice(for: countryCode, currencyCode: currencyCode) else {
            return .packBased // Default to pack-based
        }
        
        return priceInfo.priceType
    }
    
    func formatPriceDescription(for countryCode: String, currencyCode: String) -> String {
        let priceType = getPriceType(for: countryCode, currencyCode: currencyCode)
        _ = getRecommendedPrice(for: countryCode, currencyCode: currencyCode)
        _ = CurrencyManager.shared.getCurrencySymbol(for: currencyCode)
        
        switch priceType {
        case .packBased:
            return "Based on pack price (20 cigarettes)"
        case .singleBased:
            return "Based on single cigarette price"
        }
    }
}

// MARK: - Currency and Country Management
struct CurrencyInfo {
    let code: String
    let symbol: String
    let name: String
    let countryCode: String
    let countryName: String
}

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var currentCurrency: CurrencyInfo?
    @Published var availableCurrencies: [CurrencyInfo] = []
    
    private init() {
        loadAvailableCurrencies()
    }
    
    // MARK: - Currency Detection
    
    func detectUserCurrency() async -> CurrencyInfo? {
        // First try to get from device locale
        if let localeCurrency = getCurrencyFromLocale() {
            return localeCurrency
        }
        
        // Fallback to common currencies based on common countries
        return getDefaultCurrency()
    }
    
    private func getCurrencyFromLocale() -> CurrencyInfo? {
        let locale = Locale.current
        
        guard let currencyCode = locale.currency?.identifier,
              let currencySymbol = locale.currencySymbol,
              let countryCode = locale.region?.identifier else {
            return nil
        }
        
        let currencyName = locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
        let countryName = locale.localizedString(forRegionCode: countryCode) ?? countryCode
        
        return CurrencyInfo(
            code: currencyCode,
            symbol: currencySymbol,
            name: currencyName,
            countryCode: countryCode,
            countryName: countryName
        )
    }
    
    private func getDefaultCurrency() -> CurrencyInfo {
        // Default to USD if detection fails
        return CurrencyInfo(
            code: "USD",
            symbol: "$",
            name: "US Dollar",
            countryCode: "US",
            countryName: "United States"
        )
    }
    
    // MARK: - Currency Formatting
    
    func formatPrice(_ price: Double, currencyCode: String? = nil) -> String {
        let code = currencyCode ?? currentCurrency?.code ?? "USD"
        let symbol = getCurrencySymbol(for: code)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.currencySymbol = symbol
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: price)) ?? "\(symbol)\(price)"
    }
    
    func getCurrencySymbol(for code: String) -> String {
        switch code {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "INR": return "₹"
        case "CAD": return "C$"
        case "AUD": return "A$"
        case "CHF": return "CHF"
        case "CNY": return "¥"
        case "KRW": return "₩"
        default: return code
        }
    }
    
    // MARK: - Available Currencies
    
    private func loadAvailableCurrencies() {
        availableCurrencies = [
            CurrencyInfo(code: "USD", symbol: "$", name: "US Dollar", countryCode: "US", countryName: "United States"),
            CurrencyInfo(code: "EUR", symbol: "€", name: "Euro", countryCode: "EU", countryName: "European Union"),
            CurrencyInfo(code: "GBP", symbol: "£", name: "British Pound", countryCode: "GB", countryName: "United Kingdom"),
            CurrencyInfo(code: "INR", symbol: "₹", name: "Indian Rupee", countryCode: "IN", countryName: "India"),
            CurrencyInfo(code: "JPY", symbol: "¥", name: "Japanese Yen", countryCode: "JP", countryName: "Japan"),
            CurrencyInfo(code: "CAD", symbol: "C$", name: "Canadian Dollar", countryCode: "CA", countryName: "Canada"),
            CurrencyInfo(code: "AUD", symbol: "A$", name: "Australian Dollar", countryCode: "AU", countryName: "Australia"),
            CurrencyInfo(code: "CHF", symbol: "CHF", name: "Swiss Franc", countryCode: "CH", countryName: "Switzerland"),
            CurrencyInfo(code: "CNY", symbol: "¥", name: "Chinese Yuan", countryCode: "CN", countryName: "China"),
            CurrencyInfo(code: "KRW", symbol: "₩", name: "South Korean Won", countryCode: "KR", countryName: "South Korea"),
            CurrencyInfo(code: "BRL", symbol: "R$", name: "Brazilian Real", countryCode: "BR", countryName: "Brazil"),
            CurrencyInfo(code: "MXN", symbol: "$", name: "Mexican Peso", countryCode: "MX", countryName: "Mexico"),
            CurrencyInfo(code: "SGD", symbol: "S$", name: "Singapore Dollar", countryCode: "SG", countryName: "Singapore"),
            CurrencyInfo(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar", countryCode: "HK", countryName: "Hong Kong"),
            CurrencyInfo(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar", countryCode: "NZ", countryName: "New Zealand")
        ]
    }
    
    func getCurrencyInfo(for code: String) -> CurrencyInfo? {
        return availableCurrencies.first { $0.code == code }
    }
}

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    // MARK: - AppStorage for Persistence
    @AppStorage("cachedUserProfile") private var cachedUserProfileData: Data = Data()
    @AppStorage("lastProfileFetchTime") private var lastFetchTime: Double = 0
    @AppStorage("isProfileLoaded") private var isProfileLoaded: Bool = false
    @AppStorage("userCurrencyCode") var userCurrencyCode: String = ""
    @AppStorage("userCountryCode") var userCountryCode: String = ""
    @AppStorage("userCigarettePrice") var userCigarettePrice: Double = 0.0
    
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let currencyManager = CurrencyManager.shared
    private let priceManager = PriceManager.shared
    
    // MARK: - Cache Configuration
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour in seconds
    
    private init() {
        // Load cached data on initialization
        loadCachedProfile()
        setupCurrencyDetection()
        setupPriceDetection()
    }
    
    // MARK: - Currency Setup
    
    private func setupCurrencyDetection() {
        // If user hasn't set a currency, detect it automatically
        if userCurrencyCode.isEmpty {
            Task {
                if let detectedCurrency = await currencyManager.detectUserCurrency() {
                    await MainActor.run {
                        self.userCurrencyCode = detectedCurrency.code
                        self.userCountryCode = detectedCurrency.countryCode
                        self.currencyManager.currentCurrency = detectedCurrency
                    }
                }
            }
        } else {
            // Load saved currency
            if let savedCurrency = currencyManager.getCurrencyInfo(for: userCurrencyCode) {
                currencyManager.currentCurrency = savedCurrency
            }
        }
    }
    
    // MARK: - Price Setup
    
    private func setupPriceDetection() {
        // If user hasn't set a price, detect it automatically
        if userCigarettePrice == 0.0 {
            let recommendedPrice = priceManager.getRecommendedPrice(for: userCountryCode, currencyCode: userCurrencyCode)
            userCigarettePrice = recommendedPrice
        }
    }
    
    // MARK: - Currency Management
    
    func updateUserCurrency(_ currencyCode: String) async {
        guard let currencyInfo = currencyManager.getCurrencyInfo(for: currencyCode) else { return }
        
        await MainActor.run {
            self.userCurrencyCode = currencyCode
            self.userCountryCode = currencyInfo.countryCode
            self.currencyManager.currentCurrency = currencyInfo
        }
        
        // Update user profile in database
        await updateUserProfileInDatabase(currencyCode: currencyCode, countryCode: currencyInfo.countryCode)
        
        // Update price if it's still the default
        if userCigarettePrice == 0.0 {
            let newRecommendedPrice = priceManager.getRecommendedPrice(for: currencyInfo.countryCode, currencyCode: currencyCode)
            userCigarettePrice = newRecommendedPrice
            // Use combined update to update both currency and price together
            await updateUserPriceAndCurrencyInDatabase(price: newRecommendedPrice, currencyCode: currencyCode, countryCode: currencyInfo.countryCode)
        }
    }
    
    // MARK: - Price Management
    
    func updateUserPrice(_ price: Double) async {
        await MainActor.run {
            self.userCigarettePrice = price
        }
        
        // Update user profile in database
        await updateUserPriceInDatabase(price: price)
    }
    
    func updateUserPriceAndCurrency(price: Double, currencyCode: String, countryCode: String) async {
        await MainActor.run {
            self.userCigarettePrice = price
            self.userCurrencyCode = currencyCode
            self.userCountryCode = countryCode
        }
        
        // Update both price and currency in database
        await updateUserPriceAndCurrencyInDatabase(price: price, currencyCode: currencyCode, countryCode: countryCode)
    }
    
    func getRecommendedPrice() -> Double {
        return priceManager.getRecommendedPrice(for: userCountryCode, currencyCode: userCurrencyCode)
    }
    
    func getPriceType() -> PriceType {
        return priceManager.getPriceType(for: userCountryCode, currencyCode: userCurrencyCode)
    }
    
    func getPriceDescription() -> String {
        return priceManager.formatPriceDescription(for: userCountryCode, currencyCode: userCurrencyCode)
    }
    
    private func updateUserProfileInDatabase(currencyCode: String, countryCode: String) async {
        guard let userId = AuthManager.shared.getCurrentUser()?.id else { 
            print("❌ [USER MANAGER] No current user found for currency update")
            return 
        }
        
        print("🔄 [USER MANAGER] Updating currency in database...")
        print("   - User ID: \(userId)")
        print("   - Currency Code: \(currencyCode)")
        print("   - Country Code: \(countryCode)")
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("users")
                .update([
                    "currency_code": currencyCode,
                    "country_code": countryCode
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ [USER MANAGER] Currency updated successfully in database")
            print("📊 [USER MANAGER] Update response: \(response)")
            
            // Also update the local user profile if it exists
            if let profile = userProfile {
                // Create a new profile with updated currency/country
                let updatedProfile = UserProfile(
                    id: profile.id,
                    username: profile.username,
                    email: profile.email,
                    price_per_cigarette: profile.price_per_cigarette,
                    currency_code: currencyCode,
                    country_code: countryCode,
                    joined_at: profile.joined_at
                )
                userProfile = updatedProfile
                cacheUserProfile(updatedProfile)
            }
            
        } catch let error as PostgrestError {
            print("❌ [USER MANAGER] Postgrest error updating currency: \(error.message)")
            print("🔍 [USER MANAGER] Error details: \(error)")
        } catch let error as URLError {
            print("❌ [USER MANAGER] Network error updating currency: \(error.localizedDescription)")
            print("🔍 [USER MANAGER] Error code: \(error.code)")
        } catch {
            print("❌ [USER MANAGER] Failed to update currency in database: \(error.localizedDescription)")
            print("🔍 [USER MANAGER] Error type: \(type(of: error))")
        }
    }
    
    private func updateUserPriceInDatabase(price: Double) async {
        guard let userId = AuthManager.shared.getCurrentUser()?.id else { 
            print("❌ [USER MANAGER] No current user found for price update")
            return 
        }
        
        print("🔄 [USER MANAGER] Updating price in database...")
        print("   - User ID: \(userId)")
        print("   - New Price: \(price)")
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("users")
                .update([
                    "price_per_cigarette": String(price)
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ [USER MANAGER] Price updated successfully in database")
            print("📊 [USER MANAGER] Update response: \(response)")
            
            // Also update the local user profile if it exists
            if let profile = userProfile {
                // Create a new profile with updated price
                let updatedProfile = UserProfile(
                    id: profile.id,
                    username: profile.username,
                    email: profile.email,
                    price_per_cigarette: price,
                    currency_code: profile.currency_code,
                    country_code: profile.country_code,
                    joined_at: profile.joined_at
                )
                userProfile = updatedProfile
                cacheUserProfile(updatedProfile)
            }
            
        } catch let error as PostgrestError {
            print("❌ [USER MANAGER] Postgrest error updating price: \(error.message)")
            print("🔍 [USER MANAGER] Error details: \(error)")
        } catch let error as URLError {
            print("❌ [USER MANAGER] Network error updating price: \(error.localizedDescription)")
            print("🔍 [USER MANAGER] Error code: \(error.code)")
        } catch {
            print("❌ [USER MANAGER] Failed to update price in database: \(error.localizedDescription)")
            print("🔍 [USER MANAGER] Error type: \(type(of: error))")
        }
    }
    
    private func updateUserPriceAndCurrencyInDatabase(price: Double, currencyCode: String, countryCode: String) async {
        guard let userId = AuthManager.shared.getCurrentUser()?.id else { 
            print("❌ [USER MANAGER] No current user found for combined update")
            return 
        }
        
        print("🔄 [USER MANAGER] Updating price and currency in database...")
        print("   - User ID: \(userId)")
        print("   - New Price: \(price)")
        print("   - Currency Code: \(currencyCode)")
        print("   - Country Code: \(countryCode)")
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("users")
                .update([
                    "price_per_cigarette": String(price),
                    "currency_code": currencyCode,
                    "country_code": countryCode
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ [USER MANAGER] Price and currency updated successfully in database")
            print("📊 [USER MANAGER] Update response: \(response)")
            
            // Also update the local user profile if it exists
            if let profile = userProfile {
                // Create a new profile with updated values
                let updatedProfile = UserProfile(
                    id: profile.id,
                    username: profile.username,
                    email: profile.email,
                    price_per_cigarette: price,
                    currency_code: currencyCode,
                    country_code: countryCode,
                    joined_at: profile.joined_at
                )
                userProfile = updatedProfile
                cacheUserProfile(updatedProfile)
            }
            
        } catch let error as PostgrestError {
            print("❌ [USER MANAGER] Postgrest error updating price and currency: \(error.message)")
            print("🔍 [USER MANAGER] Error details: \(error)")
        } catch let error as URLError {
            print("❌ [USER MANAGER] Network error updating price and currency: \(error.localizedDescription)")
            print("🔍 [USER MANAGER] Error code: \(error.code)")
        } catch {
            print("❌ [USER MANAGER] Failed to update price and currency in database: \(error.localizedDescription)")
            print("🔍 [USER MANAGER] Error type: \(type(of: error))")
        }
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
        userCurrencyCode = ""
        userCountryCode = ""
        userCigarettePrice = 0.0
        
        print("🗑️ [USER MANAGER] User data cleared")
    }
    
    /// Updates user profile with new data
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        cacheUserProfile(profile)
        
        // Update currency if not set
        if let currencyCode = profile.currency_code, userCurrencyCode.isEmpty {
            userCurrencyCode = currencyCode
            if let currencyInfo = currencyManager.getCurrencyInfo(for: currencyCode) {
                currencyManager.currentCurrency = currencyInfo
            }
        }
        
        if let countryCode = profile.country_code, userCountryCode.isEmpty {
            userCountryCode = countryCode
        }
        
        // Update price if not set
        if profile.price_per_cigarette > 0 && userCigarettePrice == 0.0 {
            userCigarettePrice = profile.price_per_cigarette
        }
        
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
        let price = userCigarettePrice > 0 ? userCigarettePrice : (userProfile?.price_per_cigarette ?? 0)
        guard price > 0 else { return currencyManager.formatPrice(0) }
        return currencyManager.formatPrice(price)
    }
    
    var currentCurrencyInfo: CurrencyInfo? {
        return currencyManager.currentCurrency
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
