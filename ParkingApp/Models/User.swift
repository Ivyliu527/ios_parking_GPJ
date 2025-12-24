//
//  User.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

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
    
    // 方便方法：切換收藏狀態
    mutating func toggleFavorite(parkingLotId: String) {
        if favoriteParkingLotIds.contains(parkingLotId) {
            favoriteParkingLotIds.removeAll { $0 == parkingLotId }
        } else {
            favoriteParkingLotIds.append(parkingLotId)
        }
    }
    
    // 方便方法：檢查是否收藏
    func isFavorite(parkingLotId: String) -> Bool {
        return favoriteParkingLotIds.contains(parkingLotId)
    }
}
