//
//  StatisticsView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

struct StatisticsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Section 1: Health Insights
                HealthInsightsView()

                // Section 2: Consumption Trends
                ConsumptionTrendsView()

                // Section 3: Forecast
                FutureForecastView()

            }
            .padding()
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
