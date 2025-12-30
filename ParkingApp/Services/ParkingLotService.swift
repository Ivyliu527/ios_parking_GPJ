//
//  ParkingLotService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import Combine

/// 停车场服务实现
/// 数据源：data.gov.hk - 香港政府数据一站通
/// 使用 Core Data 进行本地缓存
class ParkingLotService: ParkingLotProviding, ObservableObject {
    static let shared = ParkingLotService()
    
    private let networkMonitor = NetworkMonitor.shared
    private let coreDataService = CoreDataService.shared
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60 // 24小时
    
    @Published var lastCacheTime: Date?
    @Published var isOfflineMode: Bool = false
    
    private init() {
        // 初始化时加载缓存时间
        lastCacheTime = coreDataService.getCacheTimestamp()
    }
    
    /// 获取停车场列表
    /// 优先使用缓存，过期则从网络获取
    func fetchLots() async throws -> [ParkingLot] {
        // 检查网络连接
        let isConnected = networkMonitor.isConnected
        isOfflineMode = !isConnected
        
        // 从 Core Data 加载缓存
        let cachedLots = coreDataService.loadParkingLots()
        
        // 如果有缓存且未过期，直接返回
        if let cacheTime = coreDataService.getCacheTimestamp(),
           Date().timeIntervalSince(cacheTime) < cacheExpirationInterval,
           !cachedLots.isEmpty {
            lastCacheTime = cacheTime
            return cachedLots
        }
        
        // 如果没有网络，返回缓存数据（即使过期）
        if !isConnected {
            if !cachedLots.isEmpty {
                lastCacheTime = coreDataService.getCacheTimestamp()
                return cachedLots
            }
            throw NSError(domain: "ParkingLotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "网络不可用且无缓存数据"])
        }
        
        // 从网络获取
        let lots = try await fetchLotsFromNetwork()
        
        // 保存到 Core Data
        coreDataService.saveParkingLots(lots)
        lastCacheTime = Date()
        isOfflineMode = false
        
        return lots
    }
    
    /// 从网络获取停车场数据
    /// API: https://api.data.gov.hk/v1/carpark-info-vacancy
    private func fetchLotsFromNetwork() async throws -> [ParkingLot] {
        // 获取当前语言设置
        let lang = LanguageManager.shared.currentLanguage.apiLang
        
        // 构建 API URL
        var urlComponents = URLComponents(string: "https://api.data.gov.hk/v1/carpark-info-vacancy")!
        urlComponents.queryItems = [
            URLQueryItem(name: "data", value: "info,vacancy"), // 同时获取信息和空位数据
            URLQueryItem(name: "vehicleTypes", value: "privateCar"), // 私家车
            URLQueryItem(name: "lang", value: lang)
        ]
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "ParkingLotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }
        
        // 发起网络请求
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "ParkingLotService", code: -2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        // 解析 JSON 响应
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let apiResponse = try decoder.decode(ParkingLotAPIResponse.self, from: data)
        
        // 转换为 ParkingLot 模型
        var parkingLots: [ParkingLot] = []
        
        for result in apiResponse.results ?? [] {
            guard let parkId = result.parkId,
                  let latitude = result.latitude,
                  let longitude = result.longitude else {
                continue
            }
            
            // 获取名称（优先使用当前语言）
            let displayName: String
            if let nameString = result.name {
                displayName = nameString
            } else if let nameObj = result.nameObject {
                switch lang {
                case "zh_CN":
                    displayName = nameObj.zhCN ?? nameObj.zh ?? nameObj.en ?? "Unknown"
                case "zh_TW":
                    displayName = nameObj.zh ?? nameObj.zhCN ?? nameObj.en ?? "Unknown"
                default:
                    displayName = nameObj.en ?? nameObj.zh ?? nameObj.zhCN ?? "Unknown"
                }
            } else {
                continue // 如果没有名称，跳过这条记录
            }
            
            // 获取地址
            let address = result.displayAddress ?? NSLocalizedString("not_provided")
            
            // 处理私家车数据
            var totalSpaces: Int? = nil
            var availableSpaces: Int? = nil
            var priceRules: String? = nil
            var hasEVChargers = false
            
            if let privateCar = result.privateCar {
                // 总车位 = space + spaceEV + spaceDIS + spaceUNL
                let spaces = [privateCar.space, privateCar.spaceEV, privateCar.spaceDIS, privateCar.spaceUNL]
                    .compactMap { $0 }
                    .reduce(0, +)
                totalSpaces = spaces > 0 ? spaces : privateCar.space
                
                // 可用车位（API可能不提供，暂时设为nil）
                availableSpaces = nil
                
                // EV充电桩
                hasEVChargers = (privateCar.spaceEV ?? 0) > 0
                
                // 构建价格规则
                if let hourlyCharges = privateCar.hourlyCharges, let firstCharge = hourlyCharges.first {
                    if let price = firstCharge.price {
                        priceRules = "每小时 $\(Int(price))"
                    }
                }
            }
            
            // 检查设施
            let hasEV = hasEVChargers || (result.facilities?.contains("evCharger") ?? false)
            
            // 构建设施信息
            let facilities = Facilities(
                evChargers: hasEV ? EVChargers(count: result.privateCar?.spaceEV, types: nil) : nil,
                covered: nil, // API中没有明确信息
                cctv: nil, // API中没有明确信息
                contactPhone: result.contactNo
            )
            
            // 营业状态
            let openingHours = result.openingStatus == "OPEN" ? "24小时" : NSLocalizedString("not_provided")
            
            let parkingLot = ParkingLot(
                id: parkId,
                name: displayName,
                address: address,
                latitude: latitude,
                longitude: longitude,
                totalSpaces: totalSpaces,
                availableSpaces: availableSpaces,
                openingHours: openingHours,
                priceRules: priceRules ?? NSLocalizedString("not_provided"),
                facilities: facilities,
                lastUpdated: Date()
            )
            
            parkingLots.append(parkingLot)
        }
        
        // 如果 API 返回空数据，使用模拟数据作为后备
        if parkingLots.isEmpty {
            print("Warning: API returned no data, using mock data")
            return mockParkingLots()
        }
        
        return parkingLots
    }
    
    /// 获取缓存时间戳（用于显示）
    func getCacheTimestamp() -> Date? {
        return coreDataService.getCacheTimestamp()
    }
    
    /// 模拟停车场数据（用于开发和测试）
    private func mockParkingLots() -> [ParkingLot] {
        return [
            ParkingLot(
                id: "1",
                name: "中环停车场",
                address: "香港中环干诺道中1号",
                latitude: 22.2819,
                longitude: 114.1556,
                totalSpaces: 200,
                availableSpaces: 45,
                openingHours: "24小时",
                priceRules: "首小时 $30，之后每小时 $20",
                facilities: Facilities(
                    evChargers: EVChargers(count: 10, types: ["Type 2", "CCS"]),
                    covered: true,
                    cctv: true,
                    contactPhone: "+852 2123 4567"
                ),
                lastUpdated: Date()
            ),
            ParkingLot(
                id: "2",
                name: "铜锣湾停车场",
                address: "香港铜锣湾告士打道280号",
                latitude: 22.2783,
                longitude: 114.1826,
                totalSpaces: 150,
                availableSpaces: 12,
                openingHours: "06:00 - 24:00",
                priceRules: "首小时 $25，之后每小时 $18",
                facilities: Facilities(
                    evChargers: EVChargers(count: 5, types: ["Type 2"]),
                    covered: true,
                    cctv: true,
                    contactPhone: "+852 2345 6789"
                ),
                lastUpdated: Date()
            ),
            ParkingLot(
                id: "3",
                name: "尖沙咀露天停车场",
                address: "香港尖沙咀广东道5号",
                latitude: 22.2974,
                longitude: 114.1720,
                totalSpaces: 80,
                availableSpaces: nil,
                openingHours: "07:00 - 23:00",
                priceRules: "每小时 $15",
                facilities: Facilities(
                    evChargers: nil,
                    covered: false,
                    cctv: true,
                    contactPhone: "+852 2456 7890"
                ),
                lastUpdated: Date()
            ),
            ParkingLot(
                id: "4",
                name: "湾仔智能停车场",
                address: "香港湾仔轩尼诗道200号",
                latitude: 22.2780,
                longitude: 114.1728,
                totalSpaces: 300,
                availableSpaces: 120,
                openingHours: "24小时",
                priceRules: "首小时 $35，之后每小时 $25",
                facilities: Facilities(
                    evChargers: EVChargers(count: 20, types: ["Type 2", "CCS", "CHAdeMO"]),
                    covered: true,
                    cctv: true,
                    contactPhone: "+852 2567 8901"
                ),
                lastUpdated: Date()
            ),
            ParkingLot(
                id: "5",
                name: "旺角停车场",
                address: "香港旺角弥敦道688号",
                latitude: 22.3193,
                longitude: 114.1694,
                totalSpaces: 100,
                availableSpaces: 0,
                openingHours: "08:00 - 22:00",
                priceRules: "暂未提供",
                facilities: Facilities(
                    evChargers: nil,
                    covered: false,
                    cctv: false,
                    contactPhone: nil
                ),
                lastUpdated: Date()
            )
        ]
    }
}

