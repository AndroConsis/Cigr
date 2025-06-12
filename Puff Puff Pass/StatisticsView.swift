//
//  StatisticsView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

struct StatisticsView: View {
    var body: some View {
        VStack {
            Text("📊 Statistics")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            Spacer()
            Text("Coming Soon: Health Insights, Trends, Forecasts")
                .foregroundColor(.gray)
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
