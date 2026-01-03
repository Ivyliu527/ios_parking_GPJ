//
//  ParkingSpot.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreLocation

// MARK: - 停车位数据模型

/// 停车位模型
/// 表示单个停车位的详细信息，包括位置、价格、设施等
struct ParkingSpot: Codable, Identifiable {
    let id: String
    var number: String
    var floor: Int
    var isAvailable: Bool
    var location: Location
    var pricePerHour: Double
    var features: [String] // e.g., ["EV Charging", "Covered", "Handicap"]
    
    // MARK: - 位置信息模型
    
    /// 停车位位置信息
    /// 包含停车位的经纬度坐标
    struct Location: Codable {
        var latitude: Double
        var longitude: Double
        
        /// 计算属性：坐标
        /// 将经纬度转换为 CLLocationCoordinate2D 格式
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    // MARK: - 初始化方法
    
    /// 初始化停车位
    /// - Parameters:
    ///   - id: 停车位唯一标识符
    ///   - number: 停车位编号
    ///   - floor: 所在楼层
    ///   - isAvailable: 是否可用
    ///   - location: 位置信息
    ///   - pricePerHour: 每小时价格
    ///   - features: 设施列表
    init(id: String = UUID().uuidString, number: String, floor: Int, isAvailable: Bool = true, location: Location, pricePerHour: Double, features: [String] = []) {
        self.id = id
        self.number = number
        self.floor = floor
        self.isAvailable = isAvailable
        self.location = location
        self.pricePerHour = pricePerHour
        self.features = features
    }
}

