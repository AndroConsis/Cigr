//
//  StatisticsView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

enum StatisticsTab: String, CaseIterable {
    case health = "Health"
    case trends = "Trends"
    case forecast = "Forecast"
    
    var icon: String {
        switch self {
        case .health: return "🫀"
        case .trends: return "📈"
        case .forecast: return "🔮"
        }
    }
}

struct StatisticsView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var selectedTab: StatisticsTab = .health
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Content with Slide Animation
            TabView(selection: $selectedTab) {
                // Health Insights Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HealthInsightsView()
                    }
                    .padding()
                }
                .tag(StatisticsTab.health)
                
                // Consumption Trends Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ConsumptionTrendsView()
                    }
                    .padding()
                }
                .tag(StatisticsTab.trends)
                
                // Future Forecast Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        FutureForecastView()
                    }
                    .padding()
                }
                .tag(StatisticsTab.forecast)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: selectedTab)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                // Ensure user profile is loaded for accurate price calculations
                await userManager.loadUserProfile()
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: StatisticsTab
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Buttons
            HStack(spacing: 0) {
                ForEach(StatisticsTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .frame(height: 44) // Reduced height like WhatsApp
            .background(Color(.systemBackground))
//            .overlay(
//                // Top border instead of bottom
//                Rectangle()
//                    .fill(Color(.systemGray5))
//                    .frame(height: 0.5),
//                alignment: .top
//            )
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let tab: StatisticsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) { // Reduced spacing
                // Icon
                Text(tab.icon)
                    .font(.system(size: 20)) // Smaller icon
                    .opacity(isSelected ? 1.0 : 0.6)
                
                // Text
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium)) // Smaller text
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Underline Indicator
//                Rectangle()
//                    .fill(isSelected ? Color.blue : Color.clear)
//                    .frame(height: 2) // Thinner underline
//                    .cornerRadius(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6) // Reduced padding
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
        }
    }
}
