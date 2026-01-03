//
//  ParkingViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - 停车位视图模型

/// 停车位视图模型
/// 管理停车位列表的加载、筛选和选择功能
class ParkingViewModel: ObservableObject {
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var filteredSpots: [ParkingSpot] = []
    @Published var selectedSpot: ParkingSpot?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedFloor: Int? = nil
    @Published var showOnlyAvailable = true
    
    private let parkingService = ParkingService.shared
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// 初始化时加载停车位数据
    init() {
        loadParkingSpots()
    }
    
    // MARK: - 数据加载
    
    /// 加载停车位列表
    /// 从服务层获取停车位数据
    func loadParkingSpots() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.parkingSpots = self.parkingService.parkingSpots
            self.applyFilters()
            self.isLoading = false
        }
    }
    
    // MARK: - 筛选功能
    
    /// 应用筛选
    /// 根据可用性、楼层和搜索文本筛选停车位
    func applyFilters() {
        filteredSpots = parkingSpots
        
        // Filter by availability
        if showOnlyAvailable {
            filteredSpots = filteredSpots.filter { $0.isAvailable }
        }
        
        // Filter by floor
        if let floor = selectedFloor {
            filteredSpots = filteredSpots.filter { $0.floor == floor }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filteredSpots = filteredSpots.filter {
                $0.number.localizedCaseInsensitiveContains(searchText) ||
                $0.features.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - 停车位选择
    
    /// 选择停车位
    /// 设置当前选中的停车位
    /// - Parameter spot: 选中的停车位
    func selectSpot(_ spot: ParkingSpot) {
        selectedSpot = spot
    }
    
    // MARK: - 辅助方法
    
    /// 获取楼层列表
    /// 返回所有停车位所在的楼层列表
    /// - Returns: 楼层数组，已排序
    func getFloors() -> [Int] {
        return Array(Set(parkingSpots.map { $0.floor })).sorted()
    }
}

