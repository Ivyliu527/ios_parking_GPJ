//
//  ParkingLot.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreLocation

// MARK: - 停车场数据模型

/// 停车场模型
/// 用于表示停车场的基本信息和属性
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
    
    // MARK: - 计算属性
    
    /// 计算属性：坐标
    /// 将经纬度转换为 CLLocationCoordinate2D 格式，用于地图显示
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// 计算属性：位置
    /// 将经纬度转换为 CLLocation 格式，用于距离计算
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// 是否有可用车位（nil 表示未知）
    /// 根据可用车位和总车位判断是否有空位
    var hasAvailableSpaces: Bool? {
        guard let available = availableSpaces, let total = totalSpaces else { return nil }
        return available > 0
    }
    
    /// 可用车位显示文本
    /// 格式化显示可用车位数量，格式为 "可用/总数"
    var availabilityText: String {
        if let available = availableSpaces, let total = totalSpaces {
            return "\(available)/\(total)"
        }
        return "Unknown" // 修正：直接返回字串，避免本地化問題
    }
}

// MARK: - 停车场设施模型

/// 停车场设施
/// 包含停车场的各种设施信息，如充电桩、遮盖、监控等
struct Facilities: Codable {
    let evChargers: EVChargers?
    let covered: Bool?
    let cctv: Bool?
    let contactPhone: String?
}

// MARK: - EV 充电设施模型

/// EV 充电设施
/// 表示停车场的电动汽车充电桩信息
struct EVChargers: Codable {
    let count: Int?
    let types: [String]?
}
