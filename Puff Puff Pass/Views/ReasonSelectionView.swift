//
//  ReasonSelectionView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 18/06/25.
//

import SwiftUI

// MARK: - Simple Smoking Reason
struct SmokingReason: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let color: String
}

struct ReasonSelectionView: View {
    let onReasonSelected: (SmokingReason?) -> Void
    
    @State private var selectedReason: SmokingReason?
    
    private let allReasons = [
        SmokingReason(title: "Stress", color: "#FF6B6B"),
        SmokingReason(title: "Boredom", color: "#4ECDC4"),
        SmokingReason(title: "Habit", color: "#45B7D1"),
        SmokingReason(title: "Socializing", color: "#96CEB4"),
        SmokingReason(title: "Concentration", color: "#FFEAA7"),
        SmokingReason(title: "Relaxation", color: "#DDA0DD"),
        SmokingReason(title: "Other", color: "#A8A8A8")
    ]
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow background tap to skip
                    onReasonSelected(nil)
                }
            
            // Reason selection list
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Why did you smoke?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Skip") {
                        onReasonSelected(nil)
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // List of reasons
                LazyVStack(spacing: 8) {
                    ForEach(allReasons) { reason in
                        Button(action: {
                            print("🎯 [REASON] Selected: \(reason.title)")
                            selectedReason = reason
                            onReasonSelected(reason)
                        }) {
                            HStack {
                                // Color indicator
                                Circle()
                                    .fill(Color(hex: reason.color))
                                    .frame(width: 12, height: 12)
                                
                                // Reason title
                                Text(reason.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Selection indicator
                                if selectedReason?.id == reason.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16) // Increased from 12 to 16
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.top, 100) // Reduced from 40 to 100 for better positioning
            .padding(.bottom, 40)
        }
        .onAppear {
            print("🎯 [REASON SELECTION] List view appeared")
        }
    }
}

struct ReasonSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ReasonSelectionView { reason in
            print("Selected reason: \(reason?.title ?? "None")")
        }
    }
} 
