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

/// 地址候选项
struct AddressSuggestion: Identifiable, Hashable {
    let id = UUID()
    let address: String
    let location: CLLocation
}

/// 停车场视图模型
class ParkingLotViewModel: ObservableObject {
    @Published var lots: [ParkingLot] = []
    @Published var filtered: [ParkingLot] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var addressSuggestions: [AddressSuggestion] = []
    @Published var searchReferenceLocation: CLLocation? // 用于距离排序的参考位置
    
    @Published var filters: Filters = Filters()
    @Published var sortBy: ParkingLotSortBy = .distance
    
    private let parkingLotService: ParkingLotProviding
    private var currentLocation: CLLocation?
    private let geocoder = CLGeocoder()
    
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
    
    /// 监听搜索文本变化
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
    func selectAddressSuggestion(_ suggestion: AddressSuggestion) {
        searchText = suggestion.address
        searchReferenceLocation = suggestion.location
        addressSuggestions = []
        applyFiltersAndSort(currentLocation: currentLocation)
    }
}

