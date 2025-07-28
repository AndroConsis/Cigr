//
//  Puff_Puff_PassApp.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 10/06/25.
//

import SwiftUI

@main
struct Puff_Puff_PassApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
        
    var body: some Scene {
        WindowGroup {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}
