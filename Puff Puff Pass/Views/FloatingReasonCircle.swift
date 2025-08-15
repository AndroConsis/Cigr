//
//  FloatingReasonCircle.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 18/06/25.
//

import SwiftUI

struct FloatingReasonCircle: View {
    let reason: SmokingReason
    let diameter: CGFloat
    let delay: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isVisible = false
    @State private var isFloating = false
    
    var body: some View {
        Button(action: onTap) {
            Text(reason.title)
                .font(.system(size: diameter * 0.2, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(width: diameter, height: diameter)
                .background(
                    Circle()
                        .fill(Color(hex: reason.color))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.2 : (isVisible ? 1.0 : 0.0))
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isFloating ? -20 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .animation(.easeInOut(duration: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isFloating)
        .onAppear {
            print("🎯 [FLOATING CIRCLE] \(reason.title) appeared with delay: \(delay)")
            // Staggered emergence
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                print("🎯 [FLOATING CIRCLE] \(reason.title) becoming visible")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isVisible = true
                }
                
                // Start floating after emergence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("🎯 [FLOATING CIRCLE] \(reason.title) starting to float")
                    isFloating = true
                }
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 