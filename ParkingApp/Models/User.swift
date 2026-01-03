//
//  User.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

// MARK: - 用户数据模型

/// 用户模型
/// 表示应用用户的基本信息和收藏列表
struct User: Codable, Identifiable {
    let id: String
    var email: String
    var name: String
    var phoneNumber: String
    var licensePlate: String?
    var favoriteParkingLotIds: [String] = []  // 新增：收藏的停車場ID列表
    
    init(id: String = UUID().uuidString,
         email: String,
         name: String,
         phoneNumber: String,
         licensePlate: String? = nil,
         favoriteParkingLotIds: [String] = []) {  // 新增參數
        self.id = id
        self.email = email
        self.name = name
        self.phoneNumber = phoneNumber
        self.licensePlate = licensePlate
        self.favoriteParkingLotIds = favoriteParkingLotIds
    }
    
    // MARK: - 收藏功能方法
    
    /// 切换收藏状态
    /// 如果已收藏则取消收藏，如果未收藏则添加收藏
    /// - Parameter parkingLotId: 停车场ID
    mutating func toggleFavorite(parkingLotId: String) {
        if favoriteParkingLotIds.contains(parkingLotId) {
            favoriteParkingLotIds.removeAll { $0 == parkingLotId }
        } else {
            favoriteParkingLotIds.append(parkingLotId)
        }
    }
    
    /// 检查是否收藏
    /// 判断指定的停车场是否在收藏列表中
    /// - Parameter parkingLotId: 停车场ID
    /// - Returns: 如果已收藏返回 true，否则返回 false
    func isFavorite(parkingLotId: String) -> Bool {
        return favoriteParkingLotIds.contains(parkingLotId)
    }
}
