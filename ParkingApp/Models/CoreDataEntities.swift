//  CoreDataEntities.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

// MARK: - Core Data 实体扩展

extension ParkingLotEntity {
    /// 转换为领域模型 ParkingLot
    func toParkingLot() -> ParkingLot {
        // 注意：evChargerCount 在数据模型中通常为非可选 Int32
        // 不能使用 if let 对其做可选绑定，否则会报
        // "Initializer for conditional binding must have Optional type, not 'Int32'"
        let facilities: Facilities?
        if evChargerCount > 0 {
            facilities = Facilities(
                evChargers: EVChargers(count: Int(evChargerCount), types: evChargerTypes),
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
        entity.evChargerTypes = lot.facilities?.evChargers?.types
        
        // lastUpdated：来源于远端数据的更新时间；可能为 nil
        entity.lastUpdated = lot.lastUpdated
        // cachedAt：本地缓存写入时间（用于离线模式显示“上次更新”）
        entity.cachedAt = Date()
        
        return entity
    }
}

extension ReservationEntity {
    /// 转换为领域模型 Reservation
    func toReservation() -> Reservation {
        return Reservation(
            id: id ?? UUID().uuidString,
            userId: userId ?? "",
            parkingSpotId: parkingSpotId ?? "",
            startTime: startTime ?? Date(),
            endTime: endTime,
            status: Reservation.ReservationStatus(rawValue: status ?? "active") ?? .active,
            totalCost: totalCost,
            paymentStatus: Reservation.PaymentStatus(rawValue: paymentStatus ?? "pending") ?? .pending
        )
    }
    
    /// 从领域模型 Reservation 创建或更新实体
    @discardableResult
    static func createOrUpdate(from reservation: Reservation, in context: NSManagedObjectContext) -> ReservationEntity {
        let request: NSFetchRequest<ReservationEntity> = ReservationEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", reservation.id)
        
        let entity = (try? context.fetch(request).first) ?? ReservationEntity(context: context)
        
        entity.id = reservation.id
        entity.userId = reservation.userId
        entity.parkingSpotId = reservation.parkingSpotId
        entity.startTime = reservation.startTime
        entity.endTime = reservation.endTime
        entity.status = reservation.status.rawValue
        entity.totalCost = reservation.totalCost
        entity.paymentStatus = reservation.paymentStatus.rawValue
        
        // 用于记录与远端同步时间；若做离线队列，可再加 pendingSync 字段
        entity.syncedAt = Date()
        
        return entity
    }
}

extension FavoriteEntity {
    /// 切换收藏状态；存在则删除，不存在则新增。返回当前是否为“已收藏”
    @discardableResult
    static func toggleFavorite(userId: String, parkingLotId: String, in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<FavoriteEntity> = FavoriteEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "userId == %@ AND parkingLotId == %@", userId, parkingLotId)
        
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
            return false // 已取消收藏
        } else {
            let entity = FavoriteEntity(context: context)
            entity.userId = userId
            entity.parkingLotId = parkingLotId
            entity.createdAt = Date()
            return true // 已添加收藏
        }
    }
    
    /// 检查是否已收藏
    static func isFavorite(userId: String, parkingLotId: String, in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<FavoriteEntity> = FavoriteEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "userId == %@ AND parkingLotId == %@", userId, parkingLotId)
        return (try? context.fetch(request).first) != nil
    }
    
    /// 获取用户的所有收藏（返回 parkingLotId 列表）
    static func getFavorites(userId: String, in context: NSManagedObjectContext) -> [String] {
        let request: NSFetchRequest<FavoriteEntity> = FavoriteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        let favorites = (try? context.fetch(request)) ?? []
        return favorites.compactMap { $0.parkingLotId }
    }
}
