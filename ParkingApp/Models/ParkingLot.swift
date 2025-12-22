//
//  ParkingLot.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreLocation

/// 停车场模型
struct ParkingLot: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let totalSpaces: Int?
    let availableSpaces: Int?
    let openingHours: String?
    let priceRules: String?
    let facilities: Facilities?
    let lastUpdated: Date?
    
    /// 计算属性：坐标
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// 计算属性：位置
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// 是否有可用车位（nil 表示未知）
    var hasAvailableSpaces: Bool? {
        guard let available = availableSpaces, let total = totalSpaces else { return nil }
        return available > 0
    }
    
    /// 可用车位显示文本
    var availabilityText: String {
        if let available = availableSpaces, let total = totalSpaces {
            return "\(available)/\(total)"
        }
        return NSLocalizedString("unknown")
    }
}

/// 停车场设施
struct Facilities: Codable {
    let evChargers: EVChargers?
    let covered: Bool?
    let cctv: Bool?
    let contactPhone: String?
}

/// EV 充电设施
struct EVChargers: Codable {
    let count: Int?
    let types: [String]?
}

