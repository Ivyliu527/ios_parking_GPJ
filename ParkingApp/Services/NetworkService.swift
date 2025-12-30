//
//  FirebaseService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Firebase 统一服务层 —— 处理 Auth 与 Firestore 数据读写
final class FirebaseService {
    static let shared = FirebaseService()
    
    let auth: Auth
    let db: Firestore
    
    private init() {
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        
        // 可选：配置离线缓存策略
        let settings = db.settings
        // settings.isPersistenceEnabled = true  // Firestore iOS 默认开启持久化
        db.settings = settings
    }
    
    // MARK: - Auth
    
    struct UserResponse: Codable {
        let id: String
        let email: String
        let name: String
        let phoneNumber: String
        let licensePlate: String?
        let token: String?  // 可用于自定义 token，Firebase 邮密登录不返回 JWT，这里保留字段兼容旧模型
    }
    
    /// 注册（创建账号 + 初始化用户文档）
    func register(email: String, password: String, name: String, phoneNumber: String) async throws -> UserResponse {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid
        
        // 初始化 Firestore 用户文档
        try await db.collection("users").document(uid).setData([
            "email": email,
            "name": name,
            "phoneNumber": phoneNumber,
            "favoriteIds": []
        ], merge: true)
        
        return UserResponse(
            id: uid,
            email: email,
            name: name,
            phoneNumber: phoneNumber,
            licensePlate: nil,
            token: nil
        )
    }
    
    /// 登录
    func login(email: String, password: String) async throws -> UserResponse {
        let result = try await auth.signIn(withEmail: email, password: password)
        let user = result.user
        
        // 从 Firestore 读取用户信息（若不存在则用 Auth 的基本信息）
        let docRef = db.collection("users").document(user.uid)
        let snapshot = try await docRef.getDocument()
        
        if snapshot.exists, let data = snapshot.data() {
            return UserResponse(
                id: user.uid,
                email: data["email"] as? String ?? (user.email ?? email),
                name: data["name"] as? String ?? "",
                phoneNumber: data["phoneNumber"] as? String ?? "",
                licensePlate: data["licensePlate"] as? String,
                token: nil
            )
        } else {
            // 首次登录但未初始化用户文档时可补写一份最小文档
            try await docRef.setData([
                "email": user.email ?? email,
                "name": "",
                "phoneNumber": "",
                "favoriteIds": []
            ], merge: true)
            return UserResponse(
                id: user.uid,
                email: user.email ?? email,
                name: "",
                phoneNumber: "",
                licensePlate: nil,
                token: nil
            )
        }
    }
    
    /// 登出
    func logout() throws {
        try auth.signOut()
    }
    
    /// 当前用户 UID（未登录为 nil）
    var currentUserId: String? {
        auth.currentUser?.uid
    }
    
    // MARK: - Favorites 收藏
    
    /// 覆盖式写入收藏列表
    func syncFavorites(userId: String, favoriteIds: [String]) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.setData([
            "favoriteIds": favoriteIds,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    /// 读取收藏列表
    func fetchFavorites(userId: String) async throws -> [String] {
        let ref = db.collection("users").document(userId)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists else { return [] }
        let data = snapshot.data() ?? [:]
        return data["favoriteIds"] as? [String] ?? []
    }
    
    /// 增量添加收藏
    func addFavorite(userId: String, lotId: String) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.updateData([
            "favoriteIds": FieldValue.arrayUnion([lotId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    /// 移除收藏
    func removeFavorite(userId: String, lotId: String) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.updateData([
            "favoriteIds": FieldValue.arrayRemove([lotId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
}

// MARK: - Firestore 模型

/// Firestore 中 users/{uid} 文档结构
struct UserDoc: Codable {
    var id: String?
    var email: String
    var name: String
    var phoneNumber: String
    var licensePlate: String?
    var favoriteIds: [String]
    var createdAt: Date?
    var updatedAt: Date?
    
    init(id: String, email: String, name: String, phoneNumber: String, licensePlate: String?, favoriteIds: [String], createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.email = email
        self.name = name
        self.phoneNumber = phoneNumber
        self.licensePlate = licensePlate
        self.favoriteIds = favoriteIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 错误定义（保持与原有调用方风格接近）

enum FBError: LocalizedError {
    case notLoggedIn
    case userNotFound
    case permissionDenied
    case networkUnavailable
    case underlying(Error)
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn: return "用户未登录"
        case .userNotFound: return "未找到用户数据"
        case .permissionDenied: return "没有权限执行该操作"
        case .networkUnavailable: return "网络不可用"
        case .underlying(let e): return e.localizedDescription
        }
    }
}
