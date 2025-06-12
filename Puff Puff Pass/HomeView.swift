//
//  HomeView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

struct CigaretteEntry: Codable, Identifiable {
    var id = UUID()
    var timestamp: Date
}

enum NavigationPage: Hashable {
    case statistics
}

struct HomeView: View {
    @AppStorage("pricePerCig") private var pricePerCig: String = "0"
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("joinDate") private var joinDate = ""

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showProfile = false
    @State private var selectedPage: NavigationPage?
    
    @State private var todayCount = 0
    @State private var allEntries: [CigaretteEntry] = []
    
    private var todayEntries: [CigaretteEntry] {
        allEntries.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }
    }
    
    private var totalCigarettes: Int {
        allEntries.count
    }
    
    private var totalPacks: Int {
        totalCigarettes / 20
    }
    
    private var totalSpent: Double {
        guard let price = Double(pricePerCig) else { return 0.0 }
        return Double(totalCigarettes) * price
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Text("Tracker")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Spacer()
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 28))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Circle Counter
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 200, height: 200)
                    
                    VStack {
                        Text("\(todayEntries.count)")
                            .font(.system(size: 48, weight: .bold))
                        Text("Today's Count")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Add Cigarette Button
                Button(action: {
                    let newEntry = CigaretteEntry(timestamp: Date())
                    allEntries.append(newEntry)
                    saveEntries()
                }) {
                    Text("Add Cigarette")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // Stats Tabs
                HStack(spacing: 20) {
                    StatCard(title: "Total", value: "\(totalCigarettes)", systemIcon: "flame")
                    StatCard(title: "Packs", value: "\(totalPacks)", systemIcon: "cube.box")
                    StatCard(title: "Spent", value: formattedSpent(), systemIcon: "creditcard")
                }
                .padding(.horizontal)
                
                NavigationLink(value: NavigationPage.statistics) {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Statistics")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .sheet(isPresented: $showProfile) {
                ProfileSheet(
                    name: userName,
                    email: userEmail,
                    joinDate: joinDate,
                    onLogout: {
                        isLoggedIn = false
                    }
                )
            }
            .navigationDestination(for: NavigationPage.self) { page in
                switch page {
                case .statistics:
                    StatisticsView()
                }
            }
            .onAppear {
                loadEntries()
            }
        }
    }
    
    func formattedSpent() -> String {
        if totalSpent.truncatingRemainder(dividingBy: 1) == 0 {
            return "₹\(Int(totalSpent))"
        } else {
            return String(format: "₹%.2f", totalSpent)
        }
    }

    // MARK: - Persistence
    func saveEntries() {
        if let data = try? JSONEncoder().encode(allEntries) {
            UserDefaults.standard.set(data, forKey: "cigaretteEntries")
        }
    }

    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "cigaretteEntries"),
           let decoded = try? JSONDecoder().decode([CigaretteEntry].self, from: data) {
            allEntries = decoded
        }
    }
}

// MARK: - StatCard View
struct StatCard: View {
    var title: String
    var value: String
    var systemIcon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemIcon)
                .font(.title)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct Previews_HomeView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
