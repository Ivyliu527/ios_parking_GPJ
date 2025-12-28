//
//  LoginView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "car.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 60)
                
                Text("Parking App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        authViewModel.login(email: email, password: password)
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                    
                    Button("Don't have an account? Register") {
                        showingRegister = true
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 30)
                
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .sheet(isPresented: $showingRegister) {
                RegisterView()
            }
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var phoneNumber = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Button(action: {
                        if password == confirmPassword {
                            authViewModel.register(
                                email: email,
                                password: password,
                                name: name,
                                phoneNumber: phoneNumber
                            )
                            dismiss()
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Register")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || name.isEmpty || phoneNumber.isEmpty || password != confirmPassword)
                }
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

