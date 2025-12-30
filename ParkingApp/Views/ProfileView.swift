//
//  ProfileView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            List {
                if let user = authViewModel.currentUser {
                    Section(header: Text(NSLocalizedString("profile_information"))) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section(header: Text(NSLocalizedString("account_details"))) {
                        HStack {
                            Text(NSLocalizedString("email"))
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text(NSLocalizedString("phone"))
                            Spacer()
                            Text(user.phoneNumber.isEmpty ? NSLocalizedString("not_set") : user.phoneNumber)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text(NSLocalizedString("license_plate"))
                            Spacer()
                            Text(user.licensePlate ?? NSLocalizedString("not_set"))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section(header: Text(NSLocalizedString("settings"))) {
                        NavigationLink(destination: LanguageSettingsView()) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                Text(NSLocalizedString("language_settings"))
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            HStack {
                                Spacer()
                                Text(NSLocalizedString("edit_profile"))
                                Spacer()
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            HStack {
                                Spacer()
                                Text(NSLocalizedString("logout"))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("profile_title"))
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var licensePlate: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("personal_information"))) {
                    TextField(NSLocalizedString("name"), text: $name)
                    TextField(NSLocalizedString("phone"), text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField(NSLocalizedString("license_plate"), text: $licensePlate)
                        .autocapitalization(.allCharacters)
                }
            }
            .navigationTitle(NSLocalizedString("edit_profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("save")) {
                        saveProfile()
                        dismiss()
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
            .onAppear {
                if let user = authViewModel.currentUser {
                    name = user.name
                    phoneNumber = user.phoneNumber
                    licensePlate = user.licensePlate ?? ""
                }
            }
        }
    }
    
    private func saveProfile() {
        guard var user = authViewModel.currentUser else { return }
        user.name = name
        user.phoneNumber = phoneNumber
        user.licensePlate = licensePlate.isEmpty ? nil : licensePlate
        authViewModel.currentUser = user
        
        // Save to UserDefaults
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        // 如果有网络，同步到服务器（需要服务器支持更新用户信息的 API）
        // 这里暂时只保存到本地，等服务器 API 准备好后再添加
    }
}

