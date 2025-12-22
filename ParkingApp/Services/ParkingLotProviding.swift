//
//  ParkingLotProviding.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

/// 停车场数据提供协议
protocol ParkingLotProviding {
    /// 获取停车场列表
    func fetchLots() async throws -> [ParkingLot]
}

