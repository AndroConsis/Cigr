//
//  ConsumptionTrendsView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 12/06/25.
//

import SwiftUI
import Charts

enum TrendRange: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct ConsumptionData: Identifiable {
    var id = UUID()
    var label: String
    var count: Int
    var totalCost: Double
}

struct ConsumptionTrendsView: View {
    @ObservedObject private var dataStore = CigaretteDataStore.shared
    @ObservedObject private var userManager = UserManager.shared
    @State private var selectedRange: TrendRange = .weekly

    var groupedData: [ConsumptionData] {
        let calendar = Calendar.current
        let entriesByPeriod: [String: [CigaretteEntry]] = Dictionary(grouping: dataStore.allEntries) { entry in
            let date = entry.timestamp
            let components: DateComponents

            switch selectedRange {
            case .weekly:
                components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                let startOfWeek = calendar.date(from: components) ?? date
                return "\(formatDate(startOfWeek)) Week"

            case .monthly:
                components = calendar.dateComponents([.year, .month], from: date)
                let monthDate = calendar.date(from: components) ?? date
                return formatDate(monthDate, format: "MMM yyyy")
            }
        }

        return entriesByPeriod.map { label, entries in
            let pricePerCigarette = userManager.userProfile?.price_per_cigarette ?? 0.0
            return ConsumptionData(
                label: label,
                count: entries.count,
                totalCost: Double(entries.count) * pricePerCigarette
            )
        }.sorted { $0.label < $1.label }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("📊 Consumption Trends")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                if groupedData.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)

                        Text("Your cigarette and spending trends will show up here.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        Text("Once you start logging, you’ll see how your smoking habits evolve weekly or monthly, with clear insights into your total cost.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                } else {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(TrendRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ChartSection(title: "Cigarettes Smoked", entries: groupedData.map {
                                    (label: $0.label, value: Double($0.count))
                                }, color: .red)
                                
                                ChartSection(title: "Money Spent", entries: groupedData.map {
                                    (label: $0.label, value: $0.totalCost)
                                }, color: .blue)
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func formatDate(_ date: Date, format: String = "dd MMM") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
