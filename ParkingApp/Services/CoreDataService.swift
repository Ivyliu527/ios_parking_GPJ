//
//  CoreDataService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

// MARK: - Core Data 数据服务

/// Core Data 数据服务
/// 提供停车场数据的本地存储和用户收藏管理功能
/// 使用 Core Data 进行数据持久化
class CoreDataService {
    static let shared = CoreDataService()
    
    private let persistenceController = PersistenceController.shared
    
    // MARK: - 初始化方法
    
    /// 私有初始化方法
    /// 实现单例模式
    private init() {}
    
    // MARK: - 停车场缓存
    
    /// 保存停车场列表到 Core Data
    /// 将停车场数据保存到本地数据库，并更新缓存时间戳
    /// - Parameter lots: 停车场数组
    func saveParkingLots(_ lots: [ParkingLot]) {
        let context = persistenceController.newBackgroundContext()
        context.perform {
            for lot in lots {
                _ = ParkingLotEntity.createOrUpdate(from: lot, in: context)
            }
            
            // 更新缓存时间戳
            self.updateCacheTimestamp(in: context)
            
            do {
                try context.save()
            } catch {
                print("保存停车场数据失败: \(error)")
            }
        }
    }
    
    /// 从 Core Data 加载停车场列表
    /// 从本地数据库读取所有停车场数据
    /// - Returns: 停车场数组，如果加载失败返回空数组
    func loadParkingLots() -> [ParkingLot] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ParkingLotEntity> = ParkingLotEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toParkingLot() }
        } catch {
            print("加载停车场数据失败: \(error)")
            return []
        }
    }
    
    /// 获取缓存时间戳
    /// 返回最后一次缓存数据的时间
    /// - Returns: 缓存时间戳，如果无缓存则返回 nil
    func getCacheTimestamp() -> Date? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ParkingLotEntity> = ParkingLotEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "cachedAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            if let entity = try context.fetch(request).first {
                return entity.cachedAt
            }
        } catch {
            print("获取缓存时间戳失败: \(error)")
        }
        return nil
    }
    
    /// 更新缓存时间戳
    /// 更新所有停车场实体的缓存时间
    /// - Parameter context: Core Data 上下文
    private func updateCacheTimestamp(in context: NSManagedObjectContext) {
        // 更新所有实体的缓存时间
        let request: NSFetchRequest<ParkingLotEntity> = ParkingLotEntity.fetchRequest()
        if let entities = try? context.fetch(request) {
            for entity in entities {
                entity.cachedAt = Date()
            }
        }
    }
    
    // MARK: - 用户收藏
    
    /// 切换收藏状态
    /// 如果已收藏则取消收藏，如果未收藏则添加收藏
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - parkingLotId: 停车场ID
    /// - Returns: 切换后的收藏状态，true 表示已收藏，false 表示未收藏
    func toggleFavorite(userId: String, parkingLotId: String) -> Bool {
        // 保护：检查 Core Data 模型是否已加载
        guard isCoreDataReady() else {
            print("⚠️ Core Data 未就绪，无法切换收藏状态")
            return false
        }
        
        let context = persistenceController.container.viewContext
        let isFavorite = FavoriteEntity.toggleFavorite(userId: userId, parkingLotId: parkingLotId, in: context)
        
        do {
            try context.save()
        } catch {
            print("保存收藏状态失败: \(error)")
        }
        
        return isFavorite
    }
    
    /// 检查是否已收藏
    /// 查询指定用户是否收藏了指定的停车场
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - parkingLotId: 停车场ID
    /// - Returns: 如果已收藏返回 true，否则返回 false
    func isFavorite(userId: String, parkingLotId: String) -> Bool {
        // 保护：检查 Core Data 模型是否已加载
        guard isCoreDataReady() else {
            return false
        }
        
        let context = persistenceController.container.viewContext
        return FavoriteEntity.isFavorite(userId: userId, parkingLotId: parkingLotId, in: context)
    }
    
    /// 获取用户的所有收藏
    /// 查询指定用户收藏的所有停车场ID列表
    /// - Parameter userId: 用户ID
    /// - Returns: 停车场ID数组，如果加载失败返回空数组
    func getFavorites(userId: String) -> [String] {
        // 保护：检查 Core Data 模型是否已加载
        guard isCoreDataReady() else {
            return []
        }
        
        let context = persistenceController.container.viewContext
        return FavoriteEntity.getFavorites(userId: userId, in: context)
    }
    
    // MARK: - 辅助方法
    
    /// 检查 Core Data 是否就绪（模型是否已加载）
    /// 验证 Core Data 模型是否正确加载，特别是 FavoriteEntity 是否存在
    /// - Returns: 如果 Core Data 就绪返回 true，否则返回 false
    private func isCoreDataReady() -> Bool {
        let context = persistenceController.container.viewContext
        let model = context.persistentStoreCoordinator?.managedObjectModel
        
        // 检查 FavoriteEntity 是否存在于模型中
        guard let entityDescription = model?.entitiesByName["FavoriteEntity"] else {
            print("⚠️ 错误：Core Data 模型中未找到 FavoriteEntity 实体")
            print("⚠️ 请确保 ParkingDataModel.xcdatamodeld 文件存在且包含 FavoriteEntity 实体")
            return false
        }
        
        return true
    }
    
}

