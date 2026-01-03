//
//  ParkingService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreLocation
import Combine

// MARK: - 停车位服务

/// 停车位服务
/// 管理停车位的可用性、预定和释放功能
/// 使用模拟数据进行开发和测试
class ParkingService: ObservableObject {
    static let shared = ParkingService()
    
    // MARK: - 发布属性
    
    /// 停车位列表
    @Published var parkingSpots: [ParkingSpot] = []
    
    // MARK: - 初始化方法
    
    /// 私有初始化方法
    /// 实现单例模式，初始化时加载模拟数据
    private init() {
        loadMockData()
    }
    
    // MARK: - 数据加载
    
    /// 加载模拟数据
    /// 初始化时调用，加载用于开发和测试的模拟停车位数据
    func loadMockData() {
        // Mock parking spots data
        parkingSpots = [
            ParkingSpot(
                number: "A-101",
                floor: 1,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3193, longitude: 114.1694),
                pricePerHour: 15.0,
                features: ["Covered", "Near Elevator"]
            ),
            ParkingSpot(
                number: "A-102",
                floor: 1,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3194, longitude: 114.1695),
                pricePerHour: 15.0,
                features: ["Covered"]
            ),
            ParkingSpot(
                number: "A-103",
                floor: 1,
                isAvailable: false,
                location: ParkingSpot.Location(latitude: 22.3195, longitude: 114.1696),
                pricePerHour: 15.0,
                features: ["Covered", "EV Charging"]
            ),
            ParkingSpot(
                number: "B-201",
                floor: 2,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3196, longitude: 114.1697),
                pricePerHour: 12.0,
                features: []
            ),
            ParkingSpot(
                number: "B-202",
                floor: 2,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3197, longitude: 114.1698),
                pricePerHour: 12.0,
                features: ["Handicap"]
            ),
            ParkingSpot(
                number: "C-301",
                floor: 3,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3198, longitude: 114.1699),
                pricePerHour: 10.0,
                features: []
            ),
            ParkingSpot(
                number: "C-302",
                floor: 3,
                isAvailable: true,
                location: ParkingSpot.Location(latitude: 22.3199, longitude: 114.1700),
                pricePerHour: 10.0,
                features: ["EV Charging"]
            )
        ]
    }
    
    // MARK: - 停车位查询
    
    /// 获取可用停车位
    /// 筛选出所有可用的停车位
    /// - Returns: 可用停车位数组
    func getAvailableSpots() -> [ParkingSpot] {
        return parkingSpots.filter { $0.isAvailable }
    }
    
    /// 根据ID获取停车位
    /// 通过停车位ID查找对应的停车位
    /// - Parameter id: 停车位ID
    /// - Returns: 找到的停车位，如果不存在返回 nil
    func getSpotById(_ id: String) -> ParkingSpot? {
        return parkingSpots.first { $0.id == id }
    }
    
    // MARK: - 停车位预定
    
    /// 预定停车位
    /// 将指定停车位标记为已占用
    /// - Parameter spotId: 停车位ID
    /// - Returns: 如果预定成功返回 true，否则返回 false
    func reserveSpot(_ spotId: String) -> Bool {
        if let index = parkingSpots.firstIndex(where: { $0.id == spotId && $0.isAvailable }) {
            parkingSpots[index].isAvailable = false
            return true
        }
        return false
    }
    
    /// 释放停车位
    /// 将指定停车位标记为可用
    /// - Parameter spotId: 停车位ID
    func releaseSpot(_ spotId: String) {
        if let index = parkingSpots.firstIndex(where: { $0.id == spotId }) {
            parkingSpots[index].isAvailable = true
        }
    }
}
