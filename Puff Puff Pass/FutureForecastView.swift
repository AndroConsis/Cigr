//
//  FutureForecastView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 15/06/25.
//

import SwiftUI

struct FutureForecastView: View {
    @AppStorage("pricePerCig") private var pricePerCigarette: Double = 0.0
    @AppStorage("cigaretteEntries") private var storedEntriesData: Data = Data()

    private var entries: [CigaretteEntry] {
        if let data = UserDefaults.standard.data(forKey: "cigaretteEntries"),
           let decoded = try? JSONDecoder().decode([CigaretteEntry].self, from: data) {
            return decoded
        }
        return []
    }

    private var dailyAverage: Double {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.timestamp) }
        guard !grouped.isEmpty else { return 0.0 }
        return Double(entries.count) / Double(grouped.count)
    }

    private var forecastedCigarettes: Int {
        Int(round(dailyAverage * 30))
    }

    private var forecastedSpending: Double {
        Double(forecastedCigarettes) * pricePerCigarette
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🔮 Future Projections")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 8)

                // Cigarette Forecast
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly Cigarette Forecast")
                        .font(.headline)

                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("\(forecastedCigarettes) cigarettes expected")
                            .font(.subheadline)
                    }

                    Text("Based on your current habits, this is your expected intake next month.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Spending Forecast
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly Spending Forecast")
                        .font(.headline)

                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.green)
                        Text(formattedAmount(forecastedSpending))
                            .font(.subheadline)
                    }

                    Text("Estimated cost based on your average daily consumption and current price per cigarette.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Divider()

                Text("Reducing your daily count can significantly lower this forecast.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Text("We're here to help you track and improve.")
                    .font(.footnote)
                    .foregroundColor(.green)
            }
            .padding()
        }
    }

    private func formattedAmount(_ amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "₹\(Int(amount))"
        } else {
            return String(format: "₹%.2f", amount)
        }
    }
}
