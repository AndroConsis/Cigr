//
//  HomeViewModel.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 24/06/25.
//

import Foundation
import Supabase

@MainActor
class HomeViewModel: ObservableObject {
    @Published var allEntries: [CigaretteEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Load Entries
    func loadEntries() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = AuthManager.shared.getCurrentUser()?.id else {
                throw HomeViewModelError.userNotFound
            }
            
            print("🔍 [HOME DEBUG] Loading entries for user: \(userId.uuidString)")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Use the correct Supabase query syntax
            let response: [CigaretteEntry] = try await SupabaseManager.shared.client
                .from("cigarette_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("smoked_at", ascending: false) // Most recent first
                .execute()
                .value
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("✅ [HOME DEBUG] Loaded \(response.count) entries in \(String(format: "%.2f", timeElapsed))s")
            
            self.allEntries = response
            
        } catch let error as PostgrestError {
            print("🗄️ [HOME DEBUG] Database error:")
            print("   - Code: \(String(describing: error.code))")
            print("   - Message: \(error.message)")
            
            self.errorMessage = "Failed to load entries: \(error.message)"
            
        } catch let error as URLError {
            print("🌐 [HOME DEBUG] Network error:")
            print("   - Code: \(error.code.rawValue)")
            print("   - Description: \(error.localizedDescription)")
            
            switch error.code {
            case .timedOut:
                self.errorMessage = "Request timed out. Please try again."
            case .notConnectedToInternet:
                self.errorMessage = "No internet connection. Please check your network."
            default:
                self.errorMessage = "Network error. Please try again."
            }
            
        } catch HomeViewModelError.userNotFound {
            print("👤 [HOME DEBUG] User not authenticated")
            self.errorMessage = "Please log in to view your entries."
            
        } catch {
            print("❌ [HOME DEBUG] Unexpected error:")
            print("   - Type: \(type(of: error))")
            print("   - Description: \(error.localizedDescription)")
            
            self.errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Add Entry
    func addEntry() async {
        errorMessage = nil
        
        do {
            guard let userId = AuthManager.shared.getCurrentUser()?.id else {
                throw HomeViewModelError.userNotFound
            }
            
            print("➕ [HOME DEBUG] Adding new entry for user: \(userId.uuidString)")
            
            let newEntry = CigaretteEntry(
                id: UUID(),
                userId: userId,
                timestamp: Date()
            )
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Insert and get the response
            let response: [CigaretteEntry] = try await SupabaseManager.shared.client
                .from("cigarette_entries")
                .insert(newEntry)
                .select()
                .execute()
                .value
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("✅ [HOME DEBUG] Entry added successfully in \(String(format: "%.2f", timeElapsed))s")
            
            // Add to local array (insert at beginning for most recent first)
            if let insertedEntry = response.first {
                self.allEntries.insert(insertedEntry, at: 0)
            }
            
        } catch let error as PostgrestError {
            print("🗄️ [HOME DEBUG] Database error while adding entry:")
            print("   - Code: \(String(describing: error.code))")
            print("   - Message: \(error.message)")
            
            self.errorMessage = "Failed to add entry: \(error.message)"
            
        } catch let error as URLError {
            print("🌐 [HOME DEBUG] Network error while adding entry:")
            print("   - Code: \(error.code.rawValue)")
            print("   - Description: \(error.localizedDescription)")
            
            switch error.code {
            case .timedOut:
                self.errorMessage = "Request timed out. Please try again."
            case .notConnectedToInternet:
                self.errorMessage = "No internet connection. Please check your network."
            default:
                self.errorMessage = "Network error. Please try again."
            }
            
        } catch HomeViewModelError.userNotFound {
            print("👤 [HOME DEBUG] User not authenticated while adding entry")
            self.errorMessage = "Please log in to add entries."
            
        } catch {
            print("❌ [HOME DEBUG] Unexpected error while adding entry:")
            print("   - Type: \(type(of: error))")
            print("   - Description: \(error.localizedDescription)")
            
            self.errorMessage = "Failed to add entry. Please try again."
        }
    }
    
    // MARK: - Delete Entry
    func deleteEntry(_ entry: CigaretteEntry) async {
        errorMessage = nil
        
        do {
            print("🗑️ [HOME DEBUG] Deleting entry: \(entry.id.uuidString)")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            try await SupabaseManager.shared.client
                .from("cigarette_entries")
                .delete()
                .eq("id", value: entry.id.uuidString)
                .execute()
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("✅ [HOME DEBUG] Entry deleted successfully in \(String(format: "%.2f", timeElapsed))s")
            
            // Remove from local array
            self.allEntries.removeAll { $0.id == entry.id }
            
        } catch let error as PostgrestError {
            print("🗄️ [HOME DEBUG] Database error while deleting entry:")
            print("   - Code: \(String(describing: error.code))")
            print("   - Message: \(error.message)")
            
            self.errorMessage = "Failed to delete entry: \(error.message)"
            
        } catch {
            print("❌ [HOME DEBUG] Error while deleting entry:")
            print("   - Description: \(error.localizedDescription)")
            
            self.errorMessage = "Failed to delete entry. Please try again."
        }
    }
    
    // MARK: - Refresh
    func refresh() async {
        await loadEntries()
    }
}

// MARK: - Custom Errors
enum HomeViewModelError: Error, LocalizedError {
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not authenticated"
        }
    }
}
