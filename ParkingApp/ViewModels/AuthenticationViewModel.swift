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
    
    private let networkService = NetworkService.shared
    private let networkMonitor = NetworkMonitor.shared
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    private let tokenKey = "authToken"
    
    init() {
        checkAuthentication()
    }
    
    func checkAuthentication() {
        // 检查本地存储的用户信息
        if let userData = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData),
           let _ = userDefaults.string(forKey: tokenKey) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 检查网络连接
                if !networkMonitor.isConnected {
                    // 离线模式：尝试从本地加载
                    await MainActor.run {
                        self.errorMessage = NSLocalizedString("network_unavailable")
                        self.isLoading = false
                    }
                    return
                }
                
                let response = try await networkService.login(email: email, password: password)
                
                await MainActor.run {
                    let user = User(
                        id: response.id,
                        email: response.email,
                        name: response.name,
                        phoneNumber: response.phoneNumber,
                        licensePlate: response.licensePlate
                    )
                    
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.saveUser(user)
                    
                    // 保存 token
                    if let token = response.token {
                        self.userDefaults.set(token, forKey: self.tokenKey)
                    }
                    
                    // 从 Core Data 加载收藏
                    self.loadFavoritesFromCoreData()
                    
                    // 从服务器同步收藏（如果有网络）
                    if self.networkMonitor.isConnected {
                        Task {
                            await self.syncFavoritesFromServer(userId: response.id)
                        }
                    }
                    
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func register(email: String, password: String, name: String, phoneNumber: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 检查网络连接
                if !networkMonitor.isConnected {
                    await MainActor.run {
                        self.errorMessage = NSLocalizedString("network_unavailable")
                        self.isLoading = false
                    }
                    return
                }
                
                let response = try await networkService.register(
                    email: email,
                    password: password,
                    name: name,
                    phoneNumber: phoneNumber
                )
                
                await MainActor.run {
                    let user = User(
                        id: response.id,
                        email: response.email,
                        name: response.name,
                        phoneNumber: response.phoneNumber,
                        licensePlate: response.licensePlate
                    )
                    
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.saveUser(user)
                    
                    // 保存 token
                    if let token = response.token {
                        self.userDefaults.set(token, forKey: self.tokenKey)
                    }
                    
                    // 通知 ReservationViewModel 用户已登录
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UserDidLogin"),
                        object: nil,
                        userInfo: ["userId": response.id]
                    )
                    
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: tokenKey)
    }
    
    // MARK: - 收藏功能方法（使用 Core Data）
    
    /// 切換停車場收藏狀態
    func toggleFavorite(parkingLotId: String) {
        guard let userId = currentUser?.id else { return }
        
        let isFavorite = CoreDataService.shared.toggleFavorite(userId: userId, parkingLotId: parkingLotId)
        
        // 同步到服务器（如果有网络）
        if networkMonitor.isConnected {
            Task {
                do {
                    let favorites = CoreDataService.shared.getFavorites(userId: userId)
                    try await networkService.syncFavorites(userId: userId, favoriteIds: favorites)
                } catch {
                    print("同步收藏到服务器失败: \(error)")
                }
            }
        }
    }
    
    /// 檢查是否已收藏
    func isFavorite(parkingLotId: String) -> Bool {
        guard let userId = currentUser?.id else { return false }
        return CoreDataService.shared.isFavorite(userId: userId, parkingLotId: parkingLotId)
    }
    
    /// 獲取所有收藏的停車場ID
    func getFavorites() -> [String] {
        guard let userId = currentUser?.id else { return [] }
        return CoreDataService.shared.getFavorites(userId: userId)
    }
    
    /// 从 Core Data 加载收藏到用户对象
    private func loadFavoritesFromCoreData() {
        guard var user = currentUser else { return }
        user.favoriteParkingLotIds = getFavorites()
        currentUser = user
    }
    
    /// 从服务器同步收藏到本地 Core Data
    private func syncFavoritesFromServer(userId: String) async {
        do {
            let serverFavorites = try await networkService.fetchFavorites(userId: userId)
            await MainActor.run {
                // 更新 Core Data 中的收藏
                let localFavorites = CoreDataService.shared.getFavorites(userId: userId)
                
                // 添加服务器有但本地没有的收藏
                for favoriteId in serverFavorites where !localFavorites.contains(favoriteId) {
                    _ = CoreDataService.shared.toggleFavorite(userId: userId, parkingLotId: favoriteId)
                }
                
                // 删除本地有但服务器没有的收藏（可选，根据业务需求）
                // 这里我们保留本地收藏，只添加服务器收藏
                
                // 重新加载到用户对象
                self.loadFavoritesFromCoreData()
            }
        } catch {
            print("从服务器同步收藏失败: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
}
