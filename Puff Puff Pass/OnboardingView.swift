import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    private let onboardingData = [
        OnboardingSlide(
            gradient: LinearGradient(
                colors: [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.4, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            headline: "The man walking in the tunnel has never seen the light.",
            subtitle: "Awareness is the first step. Cigr is the mirror, not the hammer."
        ),
        OnboardingSlide(
            gradient: LinearGradient(
                colors: [Color(red: 0.3, green: 0.2, blue: 0.5), Color(red: 0.6, green: 0.4, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            headline: "Change starts when we stop hiding.",
            subtitle: "Cigr helps you acknowledge your smoking, without judgment — just clarity."
        ),
        OnboardingSlide(
            gradient: LinearGradient(
                colors: [Color(red: 0.4, green: 0.2, blue: 0.6), Color(red: 0.9, green: 0.5, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            headline: "Know. Understand. Improve.",
            subtitle: "Track every cigarette, visualize patterns, forecast your path — without pressure."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            onboardingData[currentPage].gradient
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Content
                VStack(spacing: 24) {
                    Text(onboardingData[currentPage].headline)
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineLimit(nil)
                    
                    Text(onboardingData[currentPage].subtitle)
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineLimit(nil)
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16, weight: .medium))
                        }
                        
                        Spacer()
                        
                        if currentPage < onboardingData.count - 1 {
                            Button("Next") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                        } else {
                            Button("Get Started") {
                                hasSeenOnboarding = true
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold && currentPage > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    } else if value.translation.width < -threshold && currentPage < onboardingData.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                }
        )
    }
}

struct OnboardingSlide {
    let gradient: LinearGradient
    let headline: String
    let subtitle: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
} 
