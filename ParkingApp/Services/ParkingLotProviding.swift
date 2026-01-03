//
//  ParkingLotProviding.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

// MARK: - 停车场数据提供协议

/// 停车场数据提供协议
/// 定义获取停车场数据的接口，支持异步获取和缓存时间戳查询
protocol ParkingLotProviding {
    /// 获取停车场列表
    /// 异步获取停车场数据，可能从网络或缓存中获取
    /// - Returns: 停车场数组
    /// - Throws: 网络错误或其他获取数据时的错误
    func fetchLots() async throws -> [ParkingLot]
    
    /// 获取缓存时间戳
    /// 返回最后一次缓存数据的时间
    /// - Returns: 缓存时间戳，如果无缓存则返回 nil
    func getCacheTimestamp() -> Date?
}

