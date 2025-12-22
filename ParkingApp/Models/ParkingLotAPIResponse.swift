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
    let name: ParkingLotName?
    let displayAddress: String?
    let latitude: Double?
    let longitude: Double?
    let vehicleTypes: [VehicleType]?
    let heightLimit: Double?
    let contactNo: String?
    let remarks: String?
    
    enum CodingKeys: String, CodingKey {
        case parkId = "park_Id"
        case name
        case displayAddress
        case latitude
        case longitude
        case vehicleTypes
        case heightLimit
        case contactNo
        case remarks
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

struct VehicleType: Codable {
    let vehicleType: String?
    let spaces: Int?
    let availableSpaces: Int?
    let hourlyRate: Double?
    let dailyRate: Double?
    let monthlyRate: Double?
    let openingHours: String?
    let remarks: String?
}

