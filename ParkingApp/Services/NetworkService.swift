//
//  NetworkService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

/// 网络服务 - 处理与后端 API 的通信
class NetworkService {
    static let shared = NetworkService()
    
    // MARK: - API 配置
    // 请将以下 URL 替换为您的实际后端 API 地址
    // 例如：https://api.yourdomain.com/api 或 http://localhost:3000/api
    // 如果使用环境变量，可以从 Info.plist 或配置文件中读取
    private let baseURL: String = {
        // 优先从 Info.plist 读取配置
        if let apiURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
           !apiURL.isEmpty {
            return apiURL
        }
        // 默认值（开发环境）
        return "https://your-api-server.com/api"
    }()
    
    private let networkMonitor = NetworkMonitor.shared
    
    private init() {}
    
    /// 检查网络连接
    private func checkNetworkConnection() throws {
        if !networkMonitor.isConnected {
            throw NetworkError.networkUnavailable
        }
    }
    
    // MARK: - 用户认证 API
    
    /// 用户登录
    /// API 端点: POST /auth/login
    /// 请求体: { "email": String, "password": String }
    /// 响应: UserResponse { id, email, name, phoneNumber, licensePlate?, token? }
    func login(email: String, password: String) async throws -> UserResponse {
        try checkNetworkConnection()
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证 token（如果存在）
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserResponse.self, from: data)
    }
    
    /// 用户注册
    /// API 端点: POST /auth/register
    /// 请求体: { "email": String, "password": String, "name": String, "phoneNumber": String }
    /// 响应: UserResponse { id, email, name, phoneNumber, licensePlate?, token? }
    func register(email: String, password: String, name: String, phoneNumber: String) async throws -> UserResponse {
        try checkNetworkConnection()
        
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": name,
            "phoneNumber": phoneNumber
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 409 {
                throw NetworkError.userExists
            }
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserResponse.self, from: data)
    }
    
    /// 同步用户收藏到服务器
    /// API 端点: PUT /users/{userId}/favorites
    /// 请求体: { "favoriteIds": [String] }
    func syncFavorites(userId: String, favoriteIds: [String]) async throws {
        try checkNetworkConnection()
        
        guard let url = URL(string: "\(baseURL)/users/\(userId)/favorites") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证 token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "favoriteIds": favoriteIds
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
    
    /// 同步预定记录到服务器
    /// API 端点: PUT /users/{userId}/reservations
    /// 请求体: [Reservation] (JSON 数组)
    func syncReservations(userId: String, reservations: [Reservation]) async throws {
        try checkNetworkConnection()
        
        guard let url = URL(string: "\(baseURL)/users/\(userId)/reservations") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证 token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(reservations)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
    
    /// 从服务器获取用户的预定记录
    /// API 端点: GET /users/{userId}/reservations
    func fetchReservations(userId: String) async throws -> [Reservation] {
        try checkNetworkConnection()
        
        guard let url = URL(string: "\(baseURL)/users/\(userId)/reservations") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证 token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Reservation].self, from: data)
    }
    
    /// 从服务器获取用户的收藏列表
    /// API 端点: GET /users/{userId}/favorites
    func fetchFavorites(userId: String) async throws -> [String] {
        try checkNetworkConnection()
        
        guard let url = URL(string: "\(baseURL)/users/\(userId)/favorites") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证 token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let responseDict = try decoder.decode([String: [String]].self, from: data)
        return responseDict["favoriteIds"] ?? []
    }
}

// MARK: - 响应模型

struct UserResponse: Codable {
    let id: String
    let email: String
    let name: String
    let phoneNumber: String
    let licensePlate: String?
    let token: String?
}

// MARK: - 错误类型

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case userExists
    case serverError(Int)
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .unauthorized:
            return "用户名或密码错误"
        case .userExists:
            return "用户已存在"
        case .serverError(let code):
            return "服务器错误: \(code)"
        case .networkUnavailable:
            return "网络不可用"
        }
    }
}

