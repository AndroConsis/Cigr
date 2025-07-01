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
        
        var body: some Scene {
            WindowGroup {
                if isLoggedIn {
                    HomeView()
                } else {
                    LoginView()
                }
            }
        }
}
