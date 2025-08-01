//
//  WelcomeBoxView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 18/06/25.
//

import SwiftUI

struct WelcomeBoxView: View {
    let hasCigaretteHistory: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Main content
                HStack(spacing: 16) {
                    // Animated icon - arrow down to checkmark
                    Image(systemName: hasCigaretteHistory ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .opacity(0.9)
                        .rotationEffect(.degrees(hasCigaretteHistory ? 360 : 0))
                        .animation(.easeInOut(duration: 0.6), value: hasCigaretteHistory)
                    
                    // Message - uses full available space
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasCigaretteHistory ? "Keep Tracking!" : "Start Your Journey")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(hasCigaretteHistory ? 
                             "Log each cigarette to spot patterns and plan better." :
                             "Tap below to log your first cigarette and start tracking.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.6), // #663399
                    Color(red: 0.9, green: 0.5, blue: 0.3)  // #E6804D
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)





        .padding(.horizontal, 16)
    }
}

struct WelcomeBoxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WelcomeBoxView(hasCigaretteHistory: false)
            
            WelcomeBoxView(hasCigaretteHistory: true)
        }
        .padding()
        .background(Color(.systemGray6))
    }
} 
