//
//  FirebaseService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase 统一服务层

/// Firebase 统一服务层
/// 处理 Firebase Authentication 和 Firestore 数据读写
/// 提供用户认证、用户数据管理和收藏功能
final class FirebaseService {
    static let shared = FirebaseService()
    
    // MARK: - 属性
    
    /// Firebase Authentication 实例
    let auth: Auth
    
    /// Firestore 数据库实例
    let db: Firestore
    
    // MARK: - 初始化方法
    
    /// 私有初始化方法
    /// 实现单例模式，初始化 Firebase Auth 和 Firestore
    private init() {
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        
        // 可选：配置离线缓存策略
        let settings = db.settings
        // settings.isPersistenceEnabled = true  // Firestore iOS 默认开启持久化
        db.settings = settings
    }
    
    // MARK: - 用户认证
    
    // MARK: - 用户响应模型
    
    /// 用户响应模型
    /// 用于封装用户认证后的用户信息
    struct UserResponse: Codable {
        let id: String
        let email: String
        let name: String
        let phoneNumber: String
        let licensePlate: String?
        let token: String?  // 可用于自定义 token，Firebase 邮密登录不返回 JWT，这里保留字段兼容旧模型
    }
    
    /// 用户注册
    /// 创建新用户账号并在 Firestore 中初始化用户文档
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    ///   - name: 用户姓名
    ///   - phoneNumber: 用户电话
    /// - Returns: 用户响应信息
    /// - Throws: 注册过程中的错误
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
    
    /// 用户登录
    /// 使用邮箱和密码登录，并从 Firestore 读取用户信息
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    /// - Returns: 用户响应信息
    /// - Throws: 登录过程中的错误
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
    
    /// 用户登出
    /// 退出当前登录的用户
    /// - Throws: 登出过程中的错误
    func logout() throws {
        try auth.signOut()
    }
    
    /// 当前用户 UID
    /// 获取当前登录用户的唯一标识符
    /// - Returns: 用户ID，如果未登录返回 nil
    var currentUserId: String? {
        auth.currentUser?.uid
    }
    
    // MARK: - 收藏功能
    
    /// 同步收藏列表
    /// 覆盖式写入收藏列表到 Firestore
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - favoriteIds: 收藏的停车场ID列表
    /// - Throws: 同步过程中的错误
    func syncFavorites(userId: String, favoriteIds: [String]) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.setData([
            "favoriteIds": favoriteIds,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    /// 读取收藏列表
    /// 从 Firestore 读取用户的收藏列表
    /// - Parameter userId: 用户ID
    /// - Returns: 收藏的停车场ID列表
    /// - Throws: 读取过程中的错误
    func fetchFavorites(userId: String) async throws -> [String] {
        let ref = db.collection("users").document(userId)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists else { return [] }
        let data = snapshot.data() ?? [:]
        return data["favoriteIds"] as? [String] ?? []
    }
    
    /// 添加收藏
    /// 向用户的收藏列表中添加一个停车场
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - lotId: 停车场ID
    /// - Throws: 添加过程中的错误
    func addFavorite(userId: String, lotId: String) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.updateData([
            "favoriteIds": FieldValue.arrayUnion([lotId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    /// 移除收藏
    /// 从用户的收藏列表中移除一个停车场
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - lotId: 停车场ID
    /// - Throws: 移除过程中的错误
    func removeFavorite(userId: String, lotId: String) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.updateData([
            "favoriteIds": FieldValue.arrayRemove([lotId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
}

// MARK: - Firestore 数据模型

/// Firestore 用户文档结构
/// 表示 Firestore 中 users/{uid} 文档的数据结构
struct UserDoc: Codable {
    var id: String?
    var email: String
    var name: String
    var phoneNumber: String
    var licensePlate: String?
    var favoriteIds: [String]
    var createdAt: Date?
    var updatedAt: Date?
    
    // MARK: - 初始化方法
    
    /// 初始化用户文档
    /// - Parameters:
    ///   - id: 用户ID
    ///   - email: 用户邮箱
    ///   - name: 用户姓名
    ///   - phoneNumber: 用户电话
    ///   - licensePlate: 车牌号
    ///   - favoriteIds: 收藏列表
    ///   - createdAt: 创建时间
    ///   - updatedAt: 更新时间
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

// MARK: - 错误定义

/// Firebase 服务错误类型
/// 定义 Firebase 服务可能出现的各种错误
enum FBError: LocalizedError {
    case notLoggedIn
    case userNotFound
    case permissionDenied
    case networkUnavailable
    case underlying(Error)
    
    // MARK: - 错误描述
    
    /// 错误描述
    /// 返回用户友好的错误描述信息
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
