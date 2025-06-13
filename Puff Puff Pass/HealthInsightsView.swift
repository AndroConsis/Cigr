//
//  HealthInsightsView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 12/06/25.
//

import SwiftUI

struct HealthInsightsView: View {
    @AppStorage("lastSmokedTime") private var lastSmokedTime: Double = Date().timeIntervalSince1970
    let halfLife: Double = 2
    let totalHalfLivesToClear: Double = 20

    var hoursSinceLastSmoke: Double {
        let lastDate = Date(timeIntervalSince1970: lastSmokedTime)
        let interval = Date().timeIntervalSince(lastDate)
        return interval / 3600
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🧠 Health Insights")
                    .font(.title2)
                    .bold()

                VStack(alignment: .leading, spacing: 16) {
                    // Progress Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nicotine Detox Progress")
                            .font(.headline)

                        ProgressView(value: processedPercent)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .scaleEffect(x: 1, y: 2, anchor: .center)

                        Text(String(format: "%.0f%% processed", processedPercent * 100))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Your body is actively removing nicotine. Keep it up!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Time Remaining Section
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

                    // Info Box
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                Text("Nicotine has a half-life of approx. 2 hours in the body.")
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                        )
                        .frame(height: 40)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(16)
            }
            .padding()
        }
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
