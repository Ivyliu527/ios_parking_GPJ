//
//  ParkingLotAPIResponse.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

// MARK: - API 响应数据模型

/// API 响应模型
/// 用于解析 data.gov.hk API 返回的停车场数据
struct ParkingLotAPIResponse: Codable {
    let results: [ParkingLotAPIResult]?
}

// MARK: - API 停车场结果模型

/// API 停车场结果模型
/// 表示从 API 返回的单个停车场数据
struct ParkingLotAPIResult: Codable {
    let parkId: String?
    let name: String? // API返回的name可能是字符串（中文）或对象（英文）
    let nameObject: ParkingLotName? // 英文API返回的对象格式
    let displayAddress: String?
    let latitude: Double?
    let longitude: Double?
    let privateCar: PrivateCarInfo?
    let facilities: [String]?
    let contactNo: String?
    let openingStatus: String?
    
    // MARK: - 编码键映射
    
    /// 编码键映射
    /// 将 API 返回的字段名映射到 Swift 属性名
    enum CodingKeys: String, CodingKey {
        case parkId = "park_Id"
        case name
        case displayAddress
        case latitude
        case longitude
        case privateCar
        case facilities
        case contactNo
        case openingStatus = "opening_status"
    }
    
    // MARK: - 自定义解码
    
    /// 自定义解码方法
    /// 处理 name 字段可能是字符串或对象的情况
    /// - Parameter decoder: 解码器
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parkId = try? container.decode(String.self, forKey: .parkId)
        displayAddress = try? container.decode(String.self, forKey: .displayAddress)
        latitude = try? container.decode(Double.self, forKey: .latitude)
        longitude = try? container.decode(Double.self, forKey: .longitude)
        privateCar = try? container.decode(PrivateCarInfo.self, forKey: .privateCar)
        facilities = try? container.decode([String].self, forKey: .facilities)
        contactNo = try? container.decode(String.self, forKey: .contactNo)
        openingStatus = try? container.decode(String.self, forKey: .openingStatus)
        
        // 尝试解析name（可能是字符串或对象）
        if let nameString = try? container.decode(String.self, forKey: .name) {
            name = nameString
            nameObject = nil
        } else if let nameObj = try? container.decode(ParkingLotName.self, forKey: .name) {
            name = nil
            nameObject = nameObj
        } else {
            name = nil
            nameObject = nil
        }
    }
}

// MARK: - 停车场名称模型

/// 停车场名称模型
/// 支持多语言的停车场名称，包含英文、繁体中文、简体中文
struct ParkingLotName: Codable {
    let en: String?
    let zh: String?
    let zhCN: String?
    
    // MARK: - 编码键映射
    
    /// 编码键映射
    enum CodingKeys: String, CodingKey {
        case en
        case zh
        case zhCN = "zh_CN"
    }
}

// MARK: - 私家车信息模型

/// 私家车信息模型
/// 包含私家车停车位的数量、价格等信息
struct PrivateCarInfo: Codable {
    let space: Int? // 总车位
    let spaceEV: Int? // EV车位
    let spaceDIS: Int? // 残疾人车位
    let spaceUNL: Int? // 无障碍车位
    let hourlyCharges: [HourlyCharge]?
    
    // MARK: - 编码键映射
    
    /// 编码键映射
    enum CodingKeys: String, CodingKey {
        case space
        case spaceEV
        case spaceDIS
        case spaceUNL
        case hourlyCharges
    }
}

// MARK: - 小时收费模型

/// 小时收费模型
/// 表示停车场的按小时收费规则
struct HourlyCharge: Codable {
    let price: Double?
    let periodStart: String?
    let periodEnd: String?
    let type: String?
}
