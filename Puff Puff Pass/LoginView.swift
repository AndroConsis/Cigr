//
//  LoginView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false

    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Login")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                    SecureField("Password", text: $password)
                }

                if showError {
                    Text("Invalid credentials")
                        .foregroundColor(.red)
                }

                Button("Login") {   
                    let storedEmail = UserDefaults.standard.string(forKey: "userEmail")
                    let storedPassword = UserDefaults.standard.string(forKey: "userPassword")

                    if email == storedEmail && password == storedPassword {
                        isLoggedIn = true
                    } else {
                        showError = true
                    }
                }
                
                Button("Test Supabase") {
                    Task {
                        do {
                            let response = try await SupabaseManager.shared.client
                                .from("users")
                                .select()
                                .execute()

                            print("Response:", response)
                        } catch {
                            print("Supabase Error:", error)
                        }
                    }
                }

                NavigationLink("New user? Register here", destination: RegistrationView())
            }
            .navigationTitle("Login")
        }
    }
}

