//
//  ParkingLotViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

/// 停车场排序方式
enum ParkingLotSortBy {
    case distance
    case vacancies
    case priceHint
}

/// 停车场视图模型
class ParkingLotViewModel: ObservableObject {
    @Published var lots: [ParkingLot] = []
    @Published var filtered: [ParkingLot] = []
    @Published var isLoading = false
    @Published var searchText = ""
    
    @Published var filters: Filters = Filters()
    @Published var sortBy: ParkingLotSortBy = .distance
    
    private let parkingLotService: ParkingLotProviding
    private var currentLocation: CLLocation?
    
    struct Filters {
        var hasEV: Bool = false
        var covered: Bool = false
        var cctv: Bool = false
        var onlyAvailable: Bool = false
    }
    
    init(parkingLotService: ParkingLotProviding = ParkingLotService.shared) {
        self.parkingLotService = parkingLotService
    }
    
    /// 加载停车场列表
    func loadLots() {
        isLoading = true
        
        Task {
            do {
                let fetchedLots = try await parkingLotService.fetchLots()
                await MainActor.run {
                    self.lots = fetchedLots
                    self.applyFiltersAndSort(currentLocation: self.currentLocation)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading parking lots: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    /// 更新当前位置
    func updateCurrentLocation(_ location: CLLocation?) {
        currentLocation = location
        applyFiltersAndSort(currentLocation: location)
    }
    
    /// 应用筛选和排序
    func applyFiltersAndSort(currentLocation: CLLocation?) {
        var result = lots
        
        // 搜索筛选
        if !searchText.isEmpty {
            result = result.filter { lot in
                lot.name.localizedCaseInsensitiveContains(searchText) ||
                lot.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 筛选：仅显示有空位
        if filters.onlyAvailable {
            result = result.filter { lot in
                if let hasAvailable = lot.hasAvailableSpaces {
                    return hasAvailable
                }
                return false // nil 表示未知，不算有空位
            }
        }
        
        // 筛选：EV 充电
        if filters.hasEV {
            result = result.filter { lot in
                lot.facilities?.evChargers?.count ?? 0 > 0
            }
        }
        
        // 筛选：有盖
        if filters.covered {
            result = result.filter { lot in
                lot.facilities?.covered == true
            }
        }
        
        // 筛选：CCTV
        if filters.cctv {
            result = result.filter { lot in
                lot.facilities?.cctv == true
            }
        }
        
        // 排序
        result.sort { lot1, lot2 in
            switch sortBy {
            case .distance:
                guard let location = currentLocation else { return false }
                let distance1 = location.distance(from: lot1.location)
                let distance2 = location.distance(from: lot2.location)
                return distance1 < distance2
                
            case .vacancies:
                let available1 = lot1.availableSpaces ?? 0
                let available2 = lot2.availableSpaces ?? 0
                return available1 > available2
                
            case .priceHint:
                // 简单按名称排序（价格信息需要解析，这里简化处理）
                return lot1.name < lot2.name
            }
        }
        
        filtered = result
    }
    
    /// 监听搜索文本变化
    func onSearchTextChanged() {
        applyFiltersAndSort(currentLocation: currentLocation)
    }
}

