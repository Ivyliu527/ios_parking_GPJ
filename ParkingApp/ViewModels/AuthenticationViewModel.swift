//
//  AuthenticationViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let networkMonitor = NetworkMonitor.shared
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    
    init() {
        // 监听 Firebase Auth 状态变化
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadUserData(firebaseUser: user)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
        // 启动时检查当前认证状态
        checkAuthentication()
    }
    
    func checkAuthentication() {
        if let firebaseUser = Auth.auth().currentUser {
            Task {
                await loadUserData(firebaseUser: firebaseUser)
            }
        } else {
            // 尝试从本地缓存恢复（离线）
            if let userData = userDefaults.data(forKey: userKey),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }
    
    // 从 Firestore 加载用户数据
    private func loadUserData(firebaseUser: FirebaseAuth.User) async {
        do {
            let doc = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            if doc.exists, let data = doc.data() {
                let user = User(
                    id: firebaseUser.uid,
                    email: data["email"] as? String ?? firebaseUser.email ?? "",
                    name: data["name"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    licensePlate: data["licensePlate"] as? String,
                    favoriteParkingLotIds: data["favoriteIds"] as? [String] ?? []
                )
                
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.saveUser(user)
                    // 同步收藏到 Core Data
                    self.syncFavoritesToCoreData()
                }
            } else {
                // 用户文档不存在，创建默认用户数据
                let user = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    name: "",
                    phoneNumber: "",
                    licensePlate: nil,
                    favoriteParkingLotIds: []
                )
                
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.saveUser(user)
                }
                
                // 在 Firestore 中创建用户文档
                try await db.collection("users").document(firebaseUser.uid).setData([
                    "email": firebaseUser.email ?? "",
                    "name": "",
                    "phoneNumber": "",
                    "favoriteIds": []
                ], merge: true)
            }
        } catch {
            print("加载用户数据失败: \(error)")
            // 即使加载失败，也设置基本用户信息
            await MainActor.run {
                if let email = firebaseUser.email {
                    self.currentUser = User(
                        id: firebaseUser.uid,
                        email: email,
                        name: "",
                        phoneNumber: "",
                        licensePlate: nil
                    )
                    self.isAuthenticated = true
                }
            }
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Firebase Auth 登录（包装成 async/await）
                _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
                    Auth.auth().signIn(withEmail: email, password: password) { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        if let result = result {
                            continuation.resume(returning: result)
                        } else {
                            continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "登录失败"]))
                        }
                    }
                }
                
                // 登录成功，状态监听会触发 loadUserData
                await MainActor.run { self.isLoading = false }
            } catch {
                await MainActor.run {
                    let nsError = error as NSError
                    if nsError.domain == "FIRAuthErrorDomain" {
                        // 正确用法：先构造 AuthErrorCode，再使用 code 或直接 switch
                        if let code = AuthErrorCode(rawValue: nsError.code) {
                            switch code.code {
                            case .wrongPassword, .invalidEmail, .userNotFound:
                                self.errorMessage = "邮箱或密码错误"
                            case .networkError:
                                self.errorMessage = NSLocalizedString("network_unavailable")
                            case .tooManyRequests:
                                self.errorMessage = "请求过于频繁，请稍后再试"
                            case .userDisabled:
                                self.errorMessage = "该账户已被禁用"
                            default:
                                self.errorMessage = nsError.localizedDescription
                            }
                        } else {
                            self.errorMessage = nsError.localizedDescription
                        }
                    } else {
                        self.errorMessage = nsError.localizedDescription
                    }
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
                // Firebase Auth 注册
                let authResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
                    Auth.auth().createUser(withEmail: email, password: password) { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        if let result = result {
                            continuation.resume(returning: result)
                            print("Firebase Auth result: \(result)")
                        } else {
                            continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "注册失败"]))
                            print("Firebase Auth 注册失败")
                        }
                    }
                }
                
                let userId = authResult.user.uid
                
                // 在 Firestore 中创建用户文档
                try await db.collection("users").document(userId).setData([
                    "email": email,
                    "name": name,
                    "phoneNumber": phoneNumber,
                    "favoriteIds": []
                ], merge: true)
                
                // 通知 ReservationViewModel（如果有监听）
                NotificationCenter.default.post(
                    name: NSNotification.Name("UserDidLogin"),
                    object: nil,
                    userInfo: ["userId": userId]
                )
                
                // 注册成功，状态监听会触发 loadUserData
                await MainActor.run { self.isLoading = false }
            } catch {
                await MainActor.run {
                    let nsError = error as NSError
                    if nsError.domain == "FIRAuthErrorDomain" {
                        if let code = AuthErrorCode(rawValue: nsError.code) {
                            switch code.code {
                            case .emailAlreadyInUse:
                                self.errorMessage = "该邮箱已被注册"
                            case .weakPassword:
                                self.errorMessage = "密码强度不够，请使用更复杂的密码"
                            case .invalidEmail:
                                self.errorMessage = "邮箱格式不正确"
                            case .networkError:
                                self.errorMessage = NSLocalizedString("network_unavailable")
                            default:
                                self.errorMessage = nsError.localizedDescription
                            }
                        } else {
                            self.errorMessage = nsError.localizedDescription
                        }
                    } else {
                        self.errorMessage = nsError.localizedDescription
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            userDefaults.removeObject(forKey: userKey)
        } catch {
            print("登出失败: \(error)")
        }
    }
    
    // MARK: - 收藏（Core Data 同步）
    
    func toggleFavorite(parkingLotId: String) {
        // 保护：只有在用户已登录时才操作收藏
        guard isAuthenticated, let userId = currentUser?.id else {
            print("⚠️ 用户未登录，无法切换收藏状态")
            return
        }
        
        // 先更新本地 Core Data
        _ = CoreDataService.shared.toggleFavorite(userId: userId, parkingLotId: parkingLotId)
        
        // 获取更新后的收藏列表
        let favorites = CoreDataService.shared.getFavorites(userId: userId)
        
        // 同步到 Firestore
        Task {
            do {
                try await db.collection("users").document(userId).setData([
                    "favoriteIds": favorites
                ], merge: true)
                
                // 更新本地用户对象
                await MainActor.run {
                    if var user = self.currentUser {
                        user.favoriteParkingLotIds = favorites
                        self.currentUser = user
                    }
                }
            } catch {
                print("同步收藏到 Firestore 失败: \(error)")
                // 可选：发生错误时回滚本地
                _ = CoreDataService.shared.toggleFavorite(userId: userId, parkingLotId: parkingLotId)
            }
        }
    }
    
    func isFavorite(parkingLotId: String) -> Bool {
        // 保护：只有在用户已登录时才检查收藏
        guard isAuthenticated, let userId = currentUser?.id else {
            return false
        }
        
        // 优先从内存中的用户对象获取
        if let user = currentUser, user.favoriteParkingLotIds.contains(parkingLotId) {
            return true
        }
        // 从 Core Data 获取
        return CoreDataService.shared.isFavorite(userId: userId, parkingLotId: parkingLotId)
    }
    
    func getFavorites() -> [String] {
        // 保护：只有在用户已登录时才获取收藏
        guard isAuthenticated, let userId = currentUser?.id else {
            return []
        }
        
        // 优先从内存中的用户对象获取
        if let user = currentUser, !user.favoriteParkingLotIds.isEmpty {
            return user.favoriteParkingLotIds
        }
        // 从 Core Data 获取
        return CoreDataService.shared.getFavorites(userId: userId)
    }
    
    private func syncFavoritesToCoreData() {
        // 保护：只有在用户已登录且 Core Data 就绪时才同步
        guard isAuthenticated,
              let userId = currentUser?.id,
              let favorites = currentUser?.favoriteParkingLotIds else {
            return
        }
        
        let localFavorites = CoreDataService.shared.getFavorites(userId: userId)
        
        // 同步：添加 Firestore 有但本地没有的
        for favoriteId in favorites where !localFavorites.contains(favoriteId) {
            _ = CoreDataService.shared.toggleFavorite(userId: userId, parkingLotId: favoriteId)
        }
        // 如需反向删除，可按需开启
        // for favoriteId in localFavorites where !favorites.contains(favoriteId) {
        //     _ = CoreDataService.shared.toggleFavorite(userId: userId, parkingLotId: favoriteId)
        // }
    }
    
    // 更新用户资料
    func updateUserProfile(name: String, phoneNumber: String, licensePlate: String?) async throws {
        guard let userId = currentUser?.id,
              Auth.auth().currentUser != nil else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        var updateData: [String: Any] = [
            "name": name,
            "phoneNumber": phoneNumber
        ]
        if let licensePlate = licensePlate, !licensePlate.isEmpty {
            updateData["licensePlate"] = licensePlate
        } else {
            updateData["licensePlate"] = NSNull()
        }
        
        try await db.collection("users").document(userId).setData(updateData, merge: true)
        
        await MainActor.run {
            if var user = self.currentUser {
                user.name = name
                user.phoneNumber = phoneNumber
                user.licensePlate = licensePlate
                self.currentUser = user
                self.saveUser(user)
            }
        }
    }
    
    // MARK: - Private
    
    private func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
}
