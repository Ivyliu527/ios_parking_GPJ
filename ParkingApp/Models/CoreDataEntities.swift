//  CoreDataEntities.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

// MARK: - Core Data 实体扩展

// MARK: - ParkingLotEntity 扩展

extension ParkingLotEntity {
    // MARK: - 数据转换方法
    
    /// 转换为领域模型 ParkingLot
    /// 将 Core Data 实体转换为应用使用的 ParkingLot 模型
    /// - Returns: ParkingLot 模型实例
    func toParkingLot() -> ParkingLot {
        // 注意：evChargerCount 在数据模型中通常为非可选 Int32
        // 不能使用 if let 对其做可选绑定，否则会报
        // "Initializer for conditional binding must have Optional type, not 'Int32'"
        let facilities: Facilities?
        if evChargerCount > 0 {
            // evChargerTypes 是 Transformable 类型，在 Core Data 中是 NSObject?，需要转换为 [String]?
            let chargerTypes = evChargerTypes as? [String]
            facilities = Facilities(
                evChargers: EVChargers(count: Int(evChargerCount), types: chargerTypes),
                covered: covered,
                cctv: cctv,
                contactPhone: contactPhone
            )
        } else {
            facilities = Facilities(
                evChargers: nil,
                covered: covered,
                cctv: cctv,
                contactPhone: contactPhone
            )
        }
        
        return ParkingLot(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            address: address ?? "",
            latitude: latitude,
            longitude: longitude,
            // 若数据库字段是非可选 Int32，无法区分“未知”和“0”。
            // 这里用 > 0 时才转为 Int，否则返回 nil 表示“未知/未提供”。
            totalSpaces: totalSpaces > 0 ? Int(totalSpaces) : nil,
            availableSpaces: availableSpaces > 0 ? Int(availableSpaces) : nil,
            openingHours: openingHours,
            priceRules: priceRules,
            facilities: facilities,
            // lastUpdated 可能为空；保留为可选传出
            lastUpdated: lastUpdated
        )
    }
    
    /// 从领域模型 ParkingLot 创建或更新实体
    /// 如果实体已存在则更新，否则创建新实体
    /// - Parameters:
    ///   - lot: ParkingLot 模型实例
    ///   - context: Core Data 上下文
    /// - Returns: ParkingLotEntity 实例
    @discardableResult
    static func createOrUpdate(from lot: ParkingLot, in context: NSManagedObjectContext) -> ParkingLotEntity {
        let request: NSFetchRequest<ParkingLotEntity> = ParkingLotEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", lot.id)
        
        let entity = (try? context.fetch(request).first) ?? ParkingLotEntity(context: context)
        
        entity.id = lot.id
        entity.name = lot.name
        entity.address = lot.address
        entity.latitude = lot.latitude
        entity.longitude = lot.longitude
        
        // 写入时：如果希望严格区分“未知”和“0”，可将 Core Data 字段改为 Optional Int32。
        // 当前策略：nil 用 0 代替存库，读取时用 >0 判断回填。
        entity.totalSpaces = Int32(lot.totalSpaces ?? 0)
        entity.availableSpaces = Int32(lot.availableSpaces ?? 0)
        
        entity.openingHours = lot.openingHours
        entity.priceRules = lot.priceRules
        entity.contactPhone = lot.facilities?.contactPhone
        entity.covered = lot.facilities?.covered ?? false
        entity.cctv = lot.facilities?.cctv ?? false
        entity.evChargerCount = Int32(lot.facilities?.evChargers?.count ?? 0)
        // evChargerTypes 是 Transformable 类型（NSObject?），需要将 [String]? 桥接为 Objective-C 对象
        // [String] 可以自动桥接到 NSArray，NSArray 是 NSObject 的子类
        if let types = lot.facilities?.evChargers?.types {
            entity.evChargerTypes = types as NSArray
        } else {
            entity.evChargerTypes = nil
        }
        
        // lastUpdated：来源于远端数据的更新时间；可能为 nil
        entity.lastUpdated = lot.lastUpdated
        // cachedAt：本地缓存写入时间（用于离线模式显示“上次更新”）
        entity.cachedAt = Date()
        
        return entity
    }
}

// MARK: - FavoriteEntity 扩展

extension FavoriteEntity {
    // MARK: - 收藏功能方法
    
    /// 切换收藏状态
    /// 如果已收藏则删除，如果未收藏则新增。返回当前是否为"已收藏"
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - parkingLotId: 停车场ID
    ///   - context: Core Data 上下文
    /// - Returns: 切换后的收藏状态，true 表示已收藏，false 表示未收藏
    @discardableResult
    static func toggleFavorite(userId: String, parkingLotId: String, in context: NSManagedObjectContext) -> Bool {
        // 使用类型安全的 fetchRequest() 方法
        let request = FavoriteEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "userId == %@ AND parkingLotId == %@", userId, parkingLotId)
        
        do {
            if let existing = try context.fetch(request).first {
                context.delete(existing)
                return false // 已取消收藏
            } else {
                let entity = FavoriteEntity(context: context)
                entity.userId = userId
                entity.parkingLotId = parkingLotId
                entity.createdAt = Date()
                return true // 已添加收藏
            }
        } catch {
            print("⚠️ 切换收藏状态失败: \(error)")
            // 如果实体不存在，返回 false 避免崩溃
            return false
        }
    }
    
    /// 检查是否已收藏
    /// 查询指定用户是否收藏了指定的停车场
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - parkingLotId: 停车场ID
    ///   - context: Core Data 上下文
    /// - Returns: 如果已收藏返回 true，否则返回 false
    static func isFavorite(userId: String, parkingLotId: String, in context: NSManagedObjectContext) -> Bool {
        let request = FavoriteEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "userId == %@ AND parkingLotId == %@", userId, parkingLotId)
        
        do {
            return try context.fetch(request).first != nil
        } catch {
            print("⚠️ 检查收藏状态失败: \(error)")
            return false
        }
    }
    
    /// 获取用户的所有收藏
    /// 查询指定用户收藏的所有停车场ID列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - context: Core Data 上下文
    /// - Returns: 停车场ID数组
    static func getFavorites(userId: String, in context: NSManagedObjectContext) -> [String] {
        let request = FavoriteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let favorites = try context.fetch(request)
            return favorites.compactMap { $0.parkingLotId }
        } catch {
            print("⚠️ 获取收藏列表失败: \(error)")
            return []
        }
    }
}
