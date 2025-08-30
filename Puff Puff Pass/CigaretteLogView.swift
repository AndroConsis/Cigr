import SwiftUI

struct CigaretteLogView: View {
    @StateObject private var dataStore = CigaretteDataStore.shared
    @StateObject private var userManager = UserManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var sortedEntries: [CigaretteEntry] {
        dataStore.allEntries.sorted { $0.timestamp > $1.timestamp } // Most recent first
    }
    
    // Group entries by date
    private var groupedEntries: [(String, [CigaretteEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }.map { (date, entries) in
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return (formatter.string(from: date), entries.sorted { $0.timestamp > $1.timestamp })
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if dataStore.isLoading && dataStore.allEntries.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView("Loading cigarette log...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                        Text("Please wait while we fetch your smoking history")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = dataStore.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Data")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            Task {
                                await refreshData()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if groupedEntries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Smoking History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start logging your cigarettes to see your history here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedEntries, id: \.0) { dateString, entries in
                            Section(header: DateHeaderView(dateString: dateString, entryCount: entries.count)) {
                                ForEach(entries) { entry in
                                    CigaretteLogRow(entry: entry)
                                }
                            }
                        }
                        
                        // Load more indicator
                        if dataStore.hasMoreData && !dataStore.isLoadingMore {
                            HStack {
                                Spacer()
                                Button("Load More") {
                                    Task {
                                        await dataStore.loadMoreEntries()
                                    }
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        } else if dataStore.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView("Loading more...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshData()
                    }
                }
            }
            .navigationTitle("Cigarette Log")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            print("📋 [LOG VIEW] View appeared")
            print("📋 [LOG VIEW] Current entries in dataStore: \(dataStore.allEntries.count)")
            
            Task {
                print("📋 [LOG VIEW] Loading data...")
                await loadInitialData()
                
                await MainActor.run {
                    print("📋 [LOG VIEW] Data loaded:")
                    print("   - Total entries: \(sortedEntries.count)")
                    print("   - DataStore entries: \(dataStore.allEntries.count)")
                    print("   - Is loading: \(dataStore.isLoading)")
                    print("   - Has more data: \(dataStore.hasMoreData)")
                    print("   - Error message: \(dataStore.errorMessage ?? "None")")
                }
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadInitialData() async {
        await dataStore.loadEntries()
        await userManager.loadUserProfile()
    }
    
    private func refreshData() async {
        await dataStore.refresh()
        await userManager.refreshUserProfile()
    }
}

// MARK: - Date Header View
struct DateHeaderView: View {
    let dateString: String
    let entryCount: Int
    
    var body: some View {
        HStack {
            Text(dateString)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(entryCount) cigarette\(entryCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

struct CigaretteLogRow: View {
    let entry: CigaretteEntry
    
    var body: some View {
        HStack(spacing: 15) {
            // Cigarette icon
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatTime(entry.timestamp))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(timeAgo(entry.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let reason = entry.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Int(Date().timeIntervalSince(date))
        
        guard interval >= 0 else { return "just now" }
        
        let days = interval / 86400
        let hours = (interval % 86400) / 3600
        let minutes = (interval % 3600) / 60
        
        if days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else if interval > 30 {
            return "\(interval) seconds ago"
        } else {
            return "just now"
        }
    }
}

#Preview {
    CigaretteLogView()
}
