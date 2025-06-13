//
//  ChartSection.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 13/06/25.
//

import SwiftUI
import Charts

struct ChartSection: View {
    let title: String
    let entries: [(label: String, value: Double)]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Chart {
                ForEach(entries.indices, id: \.self) { i in
                    BarMark(
                        x: .value("Date", entries[i].label),
                        y: .value("Value", entries[i].value)
                    )
                    .foregroundStyle(color)
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Period")
            .chartYAxisLabel(title == "Money Spent" ? "₹" : "Count")
        }
    }
}
