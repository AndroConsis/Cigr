//
//  ProfileSheet.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

struct ProfileSheet: View {
    let onLogout: () -> Void
    
    @StateObject private var userManager = UserManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if userManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading profile...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = userManager.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Failed to load profile")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await userManager.refreshUserProfile()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Profile Content
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .padding(.top)
                        
                        Text(userManager.displayName)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text(userManager.displayEmail)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if userManager.displayJoinDate != "Unknown" {
                            Text("Joined on \(userManager.displayJoinDate)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if userManager.displayPricePerCigarette != "₹0.00" {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.green)
                                Text("Price per cigarette: \(userManager.displayPricePerCigarette)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Divider
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 1)
                                .padding(.horizontal)
                            
                            // Logout Button
                            Button(action: {
                                onLogout()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Warning text
                            Text("This will sign you out of your account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await userManager.loadUserProfile()
                }
            }
        }
    }

}

struct ProfileSheet_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSheet(onLogout: {})
    }
}

