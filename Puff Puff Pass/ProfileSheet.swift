//
//  ProfileSheet.swift
//  Puff Puff Pass
//
//  Created by Prateek Rathore on 11/06/25.
//

import SwiftUI

struct ProfileSheet: View {
    let name: String
    let email: String
    let joinDate: String
    let onLogout: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top)

                Text(name)
                    .font(.title2)
                    .bold()

                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("Joined on \(joinDate)")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    onLogout()
                }) {
                    Text("Logout")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
