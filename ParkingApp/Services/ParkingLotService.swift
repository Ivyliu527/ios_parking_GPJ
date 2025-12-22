//
//  ParkingLotService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

/// 停车场服务实现
/// 数据源：data.gov.hk - 香港政府数据一站通
/// 注意：当前使用模拟数据，真实数据源需要根据 data.gov.hk 的实际 API 进行调整
class ParkingLotService: ParkingLotProviding {
    static let shared = ParkingLotService()
    
    private let cacheKey = "parkingLotsCache"
    private let cacheTimestampKey = "parkingLotsCacheTimestamp"
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60 // 24小时
    
    private init() {}
    
    /// 获取停车场列表
    /// 优先使用缓存，过期则从网络获取
    func fetchLots() async throws -> [ParkingLot] {
        // 检查缓存
        if let cachedLots = loadCachedLots(), !isCacheExpired() {
            return cachedLots
        }
        
        // 从网络获取（当前返回模拟数据，后续替换为真实 API）
        let lots = try await fetchLotsFromNetwork()
        
        // 保存到缓存
        saveCachedLots(lots)
        
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
                  let name = result.name,
                  let latitude = result.latitude,
                  let longitude = result.longitude else {
                continue
            }
            
            // 获取名称（优先使用当前语言）
            let displayName: String
            switch lang {
            case "zh_CN":
                displayName = name.zhCN ?? name.zh ?? name.en ?? "Unknown"
            case "zh_TW":
                displayName = name.zh ?? name.zhCN ?? name.en ?? "Unknown"
            default:
                displayName = name.en ?? name.zh ?? name.zhCN ?? "Unknown"
            }
            
            // 获取地址
            let address = result.displayAddress ?? "地址未提供"
            
            // 处理车辆类型数据（优先私家车）
            var totalSpaces: Int? = nil
            var availableSpaces: Int? = nil
            var openingHours: String? = nil
            var priceRules: String? = nil
            
            if let vehicleTypes = result.vehicleTypes {
                for vehicleType in vehicleTypes {
                    if vehicleType.vehicleType == "privateCar" {
                        totalSpaces = vehicleType.spaces
                        availableSpaces = vehicleType.availableSpaces
                        openingHours = vehicleType.openingHours
                        
                        // 构建价格规则
                        var priceParts: [String] = []
                        if let hourly = vehicleType.hourlyRate {
                            priceParts.append("每小时 $\(Int(hourly))")
                        }
                        if let daily = vehicleType.dailyRate {
                            priceParts.append("每日 $\(Int(daily))")
                        }
                        if let monthly = vehicleType.monthlyRate {
                            priceParts.append("每月 $\(Int(monthly))")
                        }
                        priceRules = priceParts.isEmpty ? nil : priceParts.joined(separator: "，")
                        break
                    }
                }
            }
            
            // 构建设施信息（简化处理，实际 API 可能没有这些字段）
            let facilities = Facilities(
                evChargers: nil, // API 中没有 EV 信息
                covered: nil, // API 中没有覆盖信息
                cctv: nil, // API 中没有 CCTV 信息
                contactPhone: result.contactNo
            )
            
            let parkingLot = ParkingLot(
                id: parkId,
                name: displayName,
                address: address,
                latitude: latitude,
                longitude: longitude,
                totalSpaces: totalSpaces,
                availableSpaces: availableSpaces,
                openingHours: openingHours ?? "24小时",
                priceRules: priceRules ?? result.remarks ?? "暂未提供",
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
    
    /// 加载缓存的停车场数据
    private func loadCachedLots() -> [ParkingLot]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let lots = try? JSONDecoder().decode([ParkingLot].self, from: data) else {
            return nil
        }
        return lots
    }
    
    /// 保存停车场数据到缓存
    private func saveCachedLots(_ lots: [ParkingLot]) {
        if let data = try? JSONEncoder().encode(lots) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        }
    }
    
    /// 检查缓存是否过期
    private func isCacheExpired() -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date else {
            return true
        }
        return Date().timeIntervalSince(timestamp) > cacheExpirationInterval
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

