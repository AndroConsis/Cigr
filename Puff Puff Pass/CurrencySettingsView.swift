import SwiftUI

struct CurrencySettingsView: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCurrencyCode: String = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Current Currency Display
                VStack(spacing: 16) {
                    Text("Current Currency")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if let currentCurrency = userManager.currentCurrencyInfo {
                        VStack(spacing: 8) {
                            HStack {
                                Text(currentCurrency.symbol)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currentCurrency.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Text(currentCurrency.countryName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            
                            // Sample price display
                            Text("Sample: \(currencyManager.formatPrice(15.99))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        Text("No currency selected")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Divider()
                
                // Currency Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Currency")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(currencyManager.availableCurrencies, id: \.code) { currency in
                            CurrencyRowView(
                                currency: currency,
                                isSelected: currency.code == selectedCurrencyCode
                            ) {
                                selectedCurrencyCode = currency.code
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Update Button
                if selectedCurrencyCode != userManager.currentCurrencyInfo?.code {
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await updateCurrency()
                            }
                        }) {
                            HStack {
                                if isUpdating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isUpdating ? "Updating..." : "Update Currency")
                                    .font(.headline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isUpdating ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isUpdating)
                        .padding(.horizontal)
                        
                        Text("This will update your currency preference and affect how prices are displayed throughout the app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Currency Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedCurrencyCode = userManager.currentCurrencyInfo?.code ?? ""
        }
        .onChange(of: userManager.currentCurrencyInfo?.code) { newValue in
            selectedCurrencyCode = newValue ?? ""
        }
    }
    
    private func updateCurrency() async {
        isUpdating = true
        
        await userManager.updateUserCurrency(selectedCurrencyCode)
        
        // Add a small delay to show the update process
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await MainActor.run {
            isUpdating = false
        }
    }
}

struct CurrencyRowView: View {
    let currency: CurrencyInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(currency.symbol)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(currency.countryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CurrencySettingsView()
}
