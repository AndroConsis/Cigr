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
    @AppStorage("pricePerCigarette") private var pricePerCigarette: Double = 0.0
    @AppStorage("cigaretteEntries") private var entryData: Data = Data()
    @State private var allEntries: [CigaretteEntry] = []
    @State private var selectedRange: TrendRange = .weekly

    var groupedData: [ConsumptionData] {
        let calendar = Calendar.current
        let entriesByPeriod: [String: [CigaretteEntry]] = Dictionary(grouping: allEntries) { entry in
            let date = entry.timestamp
            let components: DateComponents

            switch selectedRange {
            case .weekly:
                components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                let startOfWeek = calendar.date(from: components) ?? date
                return "Week of \(formatDate(startOfWeek))"

            case .monthly:
                components = calendar.dateComponents([.year, .month], from: date)
                let monthDate = calendar.date(from: components) ?? date
                return formatDate(monthDate, format: "MMM yyyy")
            }
        }

        return entriesByPeriod.map { label, entries in
            ConsumptionData(
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
            .padding()
        }
        .onAppear {
            decodeEntries()
        }
    }

    private func decodeEntries() {
        if let decoded = try? JSONDecoder().decode([CigaretteEntry].self, from: entryData) {
            self.allEntries = decoded
        }
    }

    private func formatDate(_ date: Date, format: String = "dd MMM") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
