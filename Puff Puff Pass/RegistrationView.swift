//
//  RegistrationView.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 10/06/25.
//

import SwiftUI

struct RegistrationView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var pricePerCigarette = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Name", text: $name)
                        .disableAutocorrection(true)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                    SecureField("Password", text: $password)
                }

                Section(header: Text("Smoking Preferences")) {
                    TextField("Price per Cigarette", text: $pricePerCigarette)
                        .keyboardType(.decimalPad)
                }

                Button("Register") {
                    // Save user data here (use UserDefaults for now)
                    UserDefaults.standard.set(name, forKey: "userName")
                    UserDefaults.standard.set(email, forKey: "userEmail")
                    UserDefaults.standard.set(password, forKey: "userPassword")
                    UserDefaults.standard.set(pricePerCigarette, forKey: "pricePerCig")
                    UserDefaults.standard.set(Date().formatted(date: .long, time: .omitted), forKey: "joinDate")
                    isLoggedIn = true
                }
            }
            .navigationTitle("Register")
        }
    }
}
