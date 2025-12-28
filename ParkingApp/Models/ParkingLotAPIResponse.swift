//
//  ParkingLotAPIResponse.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

/// API 响应模型
struct ParkingLotAPIResponse: Codable {
    let results: [ParkingLotAPIResult]?
}

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

struct ParkingLotName: Codable {
    let en: String?
    let zh: String?
    let zhCN: String?
    
    enum CodingKeys: String, CodingKey {
        case en
        case zh
        case zhCN = "zh_CN"
    }
}

struct PrivateCarInfo: Codable {
    let space: Int? // 总车位
    let spaceEV: Int? // EV车位
    let spaceDIS: Int? // 残疾人车位
    let spaceUNL: Int? // 无障碍车位
    let hourlyCharges: [HourlyCharge]?
    
    enum CodingKeys: String, CodingKey {
        case space
        case spaceEV
        case spaceDIS
        case spaceUNL
        case hourlyCharges
    }
}

struct HourlyCharge: Codable {
    let price: Double?
    let periodStart: String?
    let periodEnd: String?
    let type: String?
}
