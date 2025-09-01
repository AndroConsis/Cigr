import SwiftUI

struct PriceSettingsView: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var customPrice: Double = 0.0
    @State private var isUpdating = false
    @State private var showPriceInput = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Current Price Display
                VStack(spacing: 16) {
                    Text("Current Price")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text(userManager.currentCurrencyInfo?.symbol ?? "$")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userManager.displayPricePerCigarette)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("per cigarette")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        
                        // Price type description
                        Text(userManager.getPriceDescription())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                
                Divider()
                
                // Recommended Price Section
                VStack(spacing: 16) {
                    Text("Recommended Price")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    let recommendedPrice = userManager.getRecommendedPrice()
                    let recommendedPriceFormatted = currencyManager.formatPrice(recommendedPrice)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text(recommendedPriceFormatted)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            if abs(userManager.userCigarettePrice - recommendedPrice) < 0.01 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                        }
                        
                        Text("Based on average prices in \(userManager.currentCurrencyInfo?.countryName ?? "your region")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if abs(userManager.userCigarettePrice - recommendedPrice) > 0.01 {
                            Button("Use Recommended Price") {
                                Task {
                                    await userManager.updateUserPrice(recommendedPrice)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Custom Price Section
                VStack(spacing: 16) {
                    Text("Custom Price")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            customPrice = userManager.userCigarettePrice
                            showPriceInput = true
                        }) {
                            HStack {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.orange)
                                
                                Text("Set Custom Price")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("Set your own price per cigarette based on local prices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Price Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPriceInput) {
                CustomPriceInputView(
                    currentPrice: userManager.userCigarettePrice,
                    currencySymbol: userManager.currentCurrencyInfo?.symbol ?? "$",
                    onSave: { newPrice in
                        Task {
                            await userManager.updateUserPrice(newPrice)
                        }
                    }
                )
            }
        }
    }
}

struct CustomPriceInputView: View {
    let currentPrice: Double
    let currencySymbol: String
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var priceText: String = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Set Custom Price")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enter the price you pay for one cigarette")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Price Input
                VStack(spacing: 16) {
                    HStack {
                        Text(currencySymbol)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        TextField("0.00", text: $priceText)
                            .font(.title)
                            .fontWeight(.semibold)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(PlainTextFieldStyle())
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Preview
                    if let price = Double(priceText), price > 0 {
                        VStack(spacing: 4) {
                            Text("Preview:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(currencySymbol)\(String(format: "%.2f", price)) per cigarette")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Info
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("This price will be used to calculate your total spending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("You can change this anytime from settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    guard let price = Double(priceText), price > 0 else { return }
                    
                    isUpdating = true
                    onSave(price)
                    
                    // Add a small delay to show the update process
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isUpdating = false
                        dismiss()
                    }
                }) {
                    HStack {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isUpdating ? "Saving..." : "Save Price")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isValidPrice ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidPrice || isUpdating)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Custom Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            priceText = String(format: "%.2f", currentPrice)
        }
    }
    
    private var isValidPrice: Bool {
        guard let price = Double(priceText) else { return false }
        return price > 0 && price < 1000 // Reasonable price range
    }
}

#Preview {
    PriceSettingsView()
}
