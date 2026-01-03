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

// MARK: - 停车场排序方式

/// 停车场排序方式
/// 定义停车场的排序选项
enum ParkingLotSortBy {
    case distance
    case vacancies
    case priceHint
}

// MARK: - 地址候选项模型

/// 地址候选项
/// 用于搜索时的地址建议
struct AddressSuggestion: Identifiable, Hashable {
    let id = UUID()
    let address: String
    let location: CLLocation
}

// MARK: - 停车场视图模型

/// 停车场视图模型
/// 管理停车场列表的加载、筛选、排序和搜索功能
/// 支持离线模式和地理位置搜索
class ParkingLotViewModel: ObservableObject {
    @Published var lots: [ParkingLot] = []
    @Published var filtered: [ParkingLot] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var addressSuggestions: [AddressSuggestion] = []
    @Published var searchReferenceLocation: CLLocation? // 用于距离排序的参考位置
    @Published var isOfflineMode = false
    @Published var lastCacheTime: Date?
    
    @Published var filters: Filters = Filters()
    @Published var sortBy: ParkingLotSortBy = .distance
    var favoriteParkingLotIds: [String] = [] // 收藏的停车场ID列表
    
    private let parkingLotService: ParkingLotService
    private let networkMonitor = NetworkMonitor.shared
    private var currentLocation: CLLocation?
    private let geocoder = CLGeocoder()
    
    // MARK: - 筛选器结构
    
    /// 筛选器结构
    /// 定义停车场列表的筛选选项
    struct Filters {
        var hasEV: Bool = false
        var onlyFavorites: Bool = false
    }
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameter parkingLotService: 停车场服务实例
    init(parkingLotService: ParkingLotService = ParkingLotService.shared) {
        self.parkingLotService = parkingLotService
        // 初始化时检查离线状态
        self.isOfflineMode = !networkMonitor.isConnected
        self.lastCacheTime = parkingLotService.getCacheTimestamp()
    }
    
    // MARK: - 数据加载
    
    /// 加载停车场列表
    /// 从服务层获取停车场数据，支持离线模式
    func loadLots() {
        isLoading = true
        
        Task {
            do {
                let fetchedLots = try await parkingLotService.fetchLots()
                await MainActor.run {
                    self.lots = fetchedLots
                    self.isOfflineMode = parkingLotService.isOfflineMode
                    self.lastCacheTime = parkingLotService.lastCacheTime ?? parkingLotService.getCacheTimestamp()
                    self.applyFiltersAndSort(currentLocation: self.currentLocation)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading parking lots: \(error)")
                    // 即使出错，也尝试从缓存加载
                    if self.lots.isEmpty {
                        let cachedLots = CoreDataService.shared.loadParkingLots()
                        if !cachedLots.isEmpty {
                            self.lots = cachedLots
                            self.isOfflineMode = true
                            self.lastCacheTime = CoreDataService.shared.getCacheTimestamp()
                        }
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - 位置管理
    
    /// 更新当前位置
    /// 更新用户当前位置，用于距离计算和排序
    /// - Parameter location: 当前位置
    func updateCurrentLocation(_ location: CLLocation?) {
        currentLocation = location
        applyFiltersAndSort(currentLocation: location)
    }
    
    // MARK: - 筛选和排序
    
    /// 应用筛选和排序
    /// 根据搜索文本、筛选条件和排序方式处理停车场列表
    /// - Parameter currentLocation: 当前位置，用于距离排序
    func applyFiltersAndSort(currentLocation: CLLocation?) {
        var result = lots
        var referenceLocation = currentLocation // 用于距离排序的参考位置
        
        // 搜索筛选
        if !searchText.isEmpty {
            // 先尝试匹配停车场名称和地址
            let nameMatches = result.filter { lot in
                lot.name.localizedCaseInsensitiveContains(searchText) ||
                lot.address.localizedCaseInsensitiveContains(searchText)
            }
            
            // 如果找到匹配的停车场，使用当前位置排序
            if !nameMatches.isEmpty {
                result = nameMatches
                referenceLocation = currentLocation
            } else {
                // 如果没有匹配，使用搜索参考位置（地理编码后的位置）
                if let searchLocation = searchReferenceLocation {
                    result = lots // 显示所有停车场，按搜索位置排序
                    referenceLocation = searchLocation
                } else {
                    result = []
                }
            }
        } else {
            referenceLocation = currentLocation
            searchReferenceLocation = nil
            addressSuggestions = []
        }
        
        // 筛选：EV 充电
        if filters.hasEV {
            result = result.filter { lot in
                lot.facilities?.evChargers?.count ?? 0 > 0
            }
        }
        
        // 筛选：我的收藏
        if filters.onlyFavorites {
            result = result.filter { lot in
                favoriteParkingLotIds.contains(lot.id)
            }
        }
        
        // 排序
        result.sort { lot1, lot2 in
            switch sortBy {
            case .distance:
                guard let location = referenceLocation else { return false }
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
    
    // MARK: - 搜索功能
    
    /// 监听搜索文本变化
    /// 当搜索文本改变时，进行名称匹配或地理编码
    func onSearchTextChanged() {
        let searchQuery = searchText.trimmingCharacters(in: .whitespaces)
        
        if searchQuery.isEmpty {
            searchReferenceLocation = nil
            addressSuggestions = []
            applyFiltersAndSort(currentLocation: currentLocation)
            return
        }
        
        // 先尝试匹配停车场名称和地址
        let nameMatches = lots.filter { lot in
            lot.name.localizedCaseInsensitiveContains(searchQuery) ||
            lot.address.localizedCaseInsensitiveContains(searchQuery)
        }
        
        if !nameMatches.isEmpty {
            // 如果找到匹配的停车场，不进行地理编码
            searchReferenceLocation = nil
            addressSuggestions = []
            applyFiltersAndSort(currentLocation: currentLocation)
        } else {
            // 如果没有匹配，进行地理编码获取地址候选
            geocodeSearchQuery(searchQuery)
        }
    }
    
    /// 地理编码搜索查询
    /// 将搜索文本转换为地理位置，用于距离排序
    /// - Parameter query: 搜索文本
    private func geocodeSearchQuery(_ query: String) {
        geocoder.cancelGeocode()
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("地理编码失败: \(error.localizedDescription)")
                    self.addressSuggestions = []
                    self.searchReferenceLocation = nil
                    self.applyFiltersAndSort(currentLocation: self.currentLocation)
                    return
                }
                
                guard let placemarks = placemarks, !placemarks.isEmpty else {
                    self.addressSuggestions = []
                    self.searchReferenceLocation = nil
                    self.applyFiltersAndSort(currentLocation: self.currentLocation)
                    return
                }
                
                // 转换地址候选
                var suggestions: [AddressSuggestion] = []
                for placemark in placemarks.prefix(5) { // 最多显示5个候选
                    if let location = placemark.location {
                        var addressComponents: [String] = []
                        if let name = placemark.name {
                            addressComponents.append(name)
                        }
                        if let thoroughfare = placemark.thoroughfare {
                            addressComponents.append(thoroughfare)
                        }
                        if let locality = placemark.locality {
                            addressComponents.append(locality)
                        }
                        let address = addressComponents.isEmpty ? query : addressComponents.joined(separator: ", ")
                        suggestions.append(AddressSuggestion(address: address, location: location))
                    }
                }
                
                self.addressSuggestions = suggestions
                
                // 如果有候选，使用第一个作为搜索参考位置
                if let firstSuggestion = suggestions.first {
                    self.searchReferenceLocation = firstSuggestion.location
                } else {
                    self.searchReferenceLocation = nil
                }
                
                self.applyFiltersAndSort(currentLocation: self.currentLocation)
            }
        }
    }
    
    /// 选择地址候选
    /// 用户选择地址建议后，更新搜索文本和参考位置
    /// - Parameter suggestion: 选中的地址建议
    func selectAddressSuggestion(_ suggestion: AddressSuggestion) {
        searchText = suggestion.address
        searchReferenceLocation = suggestion.location
        addressSuggestions = []
        applyFiltersAndSort(currentLocation: currentLocation)
    }
}

