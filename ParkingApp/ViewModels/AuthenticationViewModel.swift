//
//  AuthenticationViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    
    init() {
        checkAuthentication()
    }
    
    func checkAuthentication() {
        if let userData = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // For demo purposes, accept any email/password
            let user = User(
                email: email,
                name: email.components(separatedBy: "@").first?.capitalized ?? "User",
                phoneNumber: ""
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.saveUser(user)
            self.isLoading = false
        }
    }
    
    func register(email: String, password: String, name: String, phoneNumber: String) {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let user = User(
                email: email,
                name: name,
                phoneNumber: phoneNumber
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.saveUser(user)
            self.isLoading = false
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: userKey)
    }
    
    private func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
}

