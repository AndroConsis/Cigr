import Foundation
import Supabase

@MainActor
class CigaretteDataStore: ObservableObject {
    static let shared = CigaretteDataStore()
    
    @Published var allEntries: [CigaretteEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Load Entries
    func loadEntries() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let userId = AuthManager.shared.getCurrentUser()?.id else {
                throw DataStoreError.userNotFound
            }
            let response: [CigaretteEntry] = try await SupabaseManager.shared.client
                .from("cigarette_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("smoked_at", ascending: false)
                .execute()
                .value
            self.allEntries = response
        } catch let error as PostgrestError {
            self.errorMessage = "Failed to load entries: \(error.message)"
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                self.errorMessage = "Request timed out. Please try again."
            case .notConnectedToInternet:
                self.errorMessage = "No internet connection. Please check your network."
            default:
                self.errorMessage = "Network error. Please try again."
            }
        } catch DataStoreError.userNotFound {
            self.errorMessage = "Please log in to view your entries."
        } catch {
            self.errorMessage = "An unexpected error occurred. Please try again."
        }
        isLoading = false
    }
    
    // MARK: - Add Entry
    func addEntry(reason: String? = nil) async {
        errorMessage = nil
        do {
            guard let userId = AuthManager.shared.getCurrentUser()?.id else {
                throw DataStoreError.userNotFound
            }
            let newEntry = CigaretteEntry(
                id: UUID(),
                userId: userId,
                timestamp: Date(),
                reason: reason
            )
            let response: [CigaretteEntry] = try await SupabaseManager.shared.client
                .from("cigarette_entries")
                .insert(newEntry)
                .select()
                .execute()
                .value
            if let insertedEntry = response.first {
                self.allEntries.insert(insertedEntry, at: 0)
            }
        } catch let error as PostgrestError {
            self.errorMessage = "Failed to add entry: \(error.message)"
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                self.errorMessage = "Request timed out. Please try again."
            case .notConnectedToInternet:
                self.errorMessage = "No internet connection. Please check your network."
            default:
                self.errorMessage = "Network error. Please try again."
            }
        } catch DataStoreError.userNotFound {
            self.errorMessage = "Please log in to add entries."
        } catch {
            self.errorMessage = "Failed to add entry. Please try again."
        }
    }
    
    // MARK: - Delete Entry
    func deleteEntry(_ entry: CigaretteEntry) async {
        errorMessage = nil
        do {
            try await SupabaseManager.shared.client
                .from("cigarette_entries")
                .delete()
                .eq("id", value: entry.id.uuidString)
                .execute()
            self.allEntries.removeAll { $0.id == entry.id }
        } catch let error as PostgrestError {
            self.errorMessage = "Failed to delete entry: \(error.message)"
        } catch {
            self.errorMessage = "Failed to delete entry. Please try again."
        }
    }
    
    // MARK: - Refresh
    func refresh() async {
        await loadEntries()
    }
    
    enum DataStoreError: Error, LocalizedError {
        case userNotFound
        var errorDescription: String? {
            switch self {
            case .userNotFound:
                return "User not authenticated"
            }
        }
    }
} 
