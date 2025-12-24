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
    
    // MARK: - 收藏功能方法
    
    /// 切換停車場收藏狀態
    func toggleFavorite(parkingLotId: String) {
        guard var user = currentUser else { return }
        
        user.toggleFavorite(parkingLotId: parkingLotId)
        currentUser = user
        saveUser(user)
    }
    
    /// 檢查是否已收藏
    func isFavorite(parkingLotId: String) -> Bool {
        return currentUser?.isFavorite(parkingLotId: parkingLotId) ?? false
    }
    
    /// 獲取所有收藏的停車場ID
    func getFavorites() -> [String] {
        return currentUser?.favoriteParkingLotIds ?? []
    }
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
}
