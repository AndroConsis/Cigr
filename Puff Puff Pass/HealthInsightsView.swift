//
//  HealthInsightsView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 12/06/25.
//

import SwiftUI

struct HealthInsightsView: View {
    @ObservedObject private var dataStore = CigaretteDataStore.shared
    let halfLife: Double = 2
    let totalHalfLivesToClear: Double = 20

    private var mostRecentEntry: CigaretteEntry? {
        dataStore.allEntries.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🧠 Health Insights")
                .font(.title2)
                .bold()
                .padding([.horizontal, .top])

            if let mostRecentEntry = mostRecentEntry {
                HealthDataView(
                    lastSmokedTimestamp: mostRecentEntry.timestamp,
                    halfLife: halfLife,
                    totalHalfLivesToClear: totalHalfLivesToClear
                )
            } else {
                EmptyStateView()
            }
        }
    }
}

// MARK: - HealthDataView
struct HealthDataView: View {
    let lastSmokedTimestamp: Date
    let halfLife: Double
    let totalHalfLivesToClear: Double

    var hoursSinceLastSmoke: Double {
        // Subtract 10 minutes (600 seconds) for the delay
        max(0, (Date().timeIntervalSince(lastSmokedTimestamp) - 600) / 3600)
    }

    var nicotineRemaining: Double {
        pow(0.5, hoursSinceLastSmoke / halfLife)
    }

    var processedPercent: Double {
        1.0 - nicotineRemaining
    }

    var timeRemainingToClear: Double {
        max(0, (totalHalfLivesToClear * halfLife) - hoursSinceLastSmoke)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nicotine Detox Progress")
                    .font(.headline)

                ProgressView(value: processedPercent)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                Text(String(format: "%.0f%% of nicotine has left your body", processedPercent * 100))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)

            HStack(spacing: 12) {
                Image(systemName: "hourglass.bottomhalf.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Until Nicotine-Free")
                        .font(.headline)
                    Text(timeRemainingFormatted())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Nicotine has a half-life of approx. 2 hours in the body.")
                    .font(.caption)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }

    private func timeRemainingFormatted() -> String {
        let hours = Int(timeRemainingToClear)
        let minutes = Int((timeRemainingToClear - Double(hours)) * 60)
        if hours == 0 && minutes == 0 {
            return "You are nicotine-free 🎉"
        }
        return "\(hours)h \(minutes)m remaining"
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lungs")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)

            Text("No Smoking Data Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Log your first cigarette on the Home screen to see your health insights and detox progress.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
}
